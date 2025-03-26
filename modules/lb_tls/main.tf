# Create a Target Group for the Application Load Balancer (ALB)
resource "aws_lb_target_group" "mission_app" {
  name     = "${var.namespace}-lb-tg"  # Name of the target group
  port     = 443                      # Port the target group listens on (HTTPS)
  protocol = "HTTPS"                  # Protocol for the target group (HTTPS)
  vpc_id   = var.vpc_id               # VPC ID to associate the target group with

  # Configure stickiness (session affinity) using a cookie
  stickiness {
    type            = "lb_cookie"       # Type of stickiness (Load Balancer cookie)
    cookie_duration = 1800              # Duration for which the cookie is valid (in seconds)
    enabled         = true              # Enable stickiness
  }

  # Configure health check settings for the target group
  health_check {
    healthy_threshold   = 3              # Number of consecutive successful health checks required
    unhealthy_threshold = 10             # Number of consecutive failed health checks before considering unhealthy
    timeout             = 5              # Timeout for each health check attempt (in seconds)
    interval            = 10             # Time between each health check attempt (in seconds)
    path                = "/"            # Path to check for health (root path)
    port                = 443            # Port to check for health
    protocol            = "HTTPS"        # Protocol used for health check (HTTPS)
  }
}

# Create an Application Load Balancer (ALB)
resource "aws_lb" "mission_app" {
  name               = "${var.namespace}-alb"      # Name of the load balancer
  internal           = false                      # Set to false for an internet-facing load balancer
  load_balancer_type = "application"              # Type of load balancer (Application Load Balancer)
  subnets            = var.private_subnet_id       # Subnet IDs to associate with the load balancer

  # Tag the load balancer for identification
  tags = {
    Name = "${var.namespace}-lb"  # Tag for the load balancer
  }

  # Security group for the load balancer
  security_groups = var.security_group_app_id  # Security group IDs associated with the ALB
}

# Create a listener for HTTP (port 80) on the Application Load Balancer
resource "aws_lb_listener" "mission_app_http" {
  load_balancer_arn = aws_lb.mission_app.arn   # ALB ARN for which the listener is created
  port              = "80"                      # Port for the listener (HTTP)
  protocol          = "HTTP"                    # Protocol for the listener (HTTP)

  # Default action to forward HTTP traffic to the target group
  default_action {
    type             = "forward"  # Action type is forward
    target_group_arn = aws_lb_target_group.mission_app.arn  # ARN of the target group to forward traffic to
  }
}

# Create a listener rule to forward traffic to the target group based on a custom HTTP header "X-Request"
resource "aws_lb_listener_rule" "redirect_cloudfront_to_http" {
  listener_arn = aws_lb_listener.mission_app_http.arn  # Listener ARN for HTTP traffic
  priority     = 100                                  # Priority for the rule (lower numbers are higher priority)

  # Action to forward traffic to the target group
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mission_app.arn  # Forward traffic to this target group
  }

  # Condition based on the "X-Request" HTTP header
  condition {
    http_header {
      http_header_name = "X-Request"               # Check for the "X-Request" header
      values           = [aws_lb.mission_app.dns_name]  # Forward traffic based on the DNS name of the load balancer
    }
  }
}

# Create a listener rule to redirect HTTP traffic to HTTPS (301 redirect)
resource "aws_lb_listener_rule" "redirect_http_to_https" {
  listener_arn = aws_lb_listener.mission_app_http.arn  # Listener ARN for HTTP traffic
  priority     = 200                                  # Priority for the rule

  # Action to redirect HTTP traffic to HTTPS
  action {
    type = "redirect"
    redirect {
      port        = "443"         # Redirect to port 443 (HTTPS)
      protocol    = "HTTPS"       # Use HTTPS for the redirection
      status_code = "HTTP_301"    # Set HTTP status code to 301 (permanent redirect)
    }
  }

  # Condition based on the host header
  condition {
    host_header {
      values = [aws_lb.mission_app.dns_name]  # Redirect traffic based on the ALB's DNS name
    }
  }
}

# Generate a private key for the SSL certificate
resource "tls_private_key" "mission_app" {
  algorithm = "RSA"  # Use RSA algorithm for private key generation
}

# Create a self-signed certificate for the Application Load Balancer
resource "tls_self_signed_cert" "mission_app" {
  private_key_pem = tls_private_key.mission_app.private_key_pem  # Private key for the certificate

  validity_period_hours = 8760  # Certificate validity period (1 year)

  # Renew the certificate early if Terraform is run within 3 hours of expiry
  early_renewal_hours = 3

  # Allowed uses for the certificate
  allowed_uses = [
    "key_encipherment",  # Allows the certificate to be used for key encipherment
    "digital_signature", # Allows the certificate to be used for digital signature
    "server_auth",       # Allows the certificate to be used for server authentication
  ]

  dns_names = [
    aws_lb.mission_app.dns_name  # Use the ALB's DNS name for the certificate
  ]

  # Certificate subject details
  subject {
    common_name         = aws_lb.mission_app.dns_name  # Common name (e.g., the ALB's DNS name)
    organization        = "Amazon Web Services"        # Organization name
    organizational_unit = "WWPS ProServe"              # Organizational unit
    country             = "USA"                         # Country
    locality            = "San Diego"                  # Locality
  }
}

# Create an ACM certificate using the self-signed certificate
resource "aws_acm_certificate" "mission_app_private" {
  private_key      = tls_private_key.mission_app.private_key_pem   # Private key for the certificate
  certificate_body = tls_self_signed_cert.mission_app.cert_pem      # Certificate body from the self-signed certificate
}

# Upload the private key to an S3 bucket for secure storage
resource "aws_s3_object" "mission_app-private_key" {
  bucket  = var.bucket_name  # S3 bucket to store the private key
  key     = "server.key"     # Key (file name) for the private key
  content = tls_private_key.mission_app.private_key_pem  # Content of the private key
}

# Upload the public key (certificate) to an S3 bucket for secure storage
resource "aws_s3_object" "mission_app-public_key" {
  bucket  = var.bucket_name  # S3 bucket to store the public key (certificate)
  key     = "server.crt"     # Key (file name) for the certificate
  content = tls_self_signed_cert.mission_app.cert_pem  # Content of the public key (certificate)
}

# Create a listener for HTTPS (port 443) on the Application Load Balancer
resource "aws_lb_listener" "mission_app_https" {
  load_balancer_arn = aws_lb.mission_app.arn   # ALB ARN for which the listener is created
  port              = "443"                      # Port for the listener (HTTPS)
  protocol          = "HTTPS"                    # Protocol for the listener (HTTPS)

  # Default action to forward HTTPS traffic to the target group
  default_action {
    type             = "forward"  # Action type is forward
    target_group_arn = aws_lb_target_group.mission_app.arn  # ARN of the target group to forward traffic to
  }

  # Attach the ACM certificate to the listener for HTTPS
  certificate_arn = aws_acm_certificate.mission_app_private.arn  # ARN of the ACM certificate
}
