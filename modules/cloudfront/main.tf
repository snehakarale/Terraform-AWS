# CloudFront Distribution for the mission app frontend
resource "aws_cloudfront_distribution" "mission_app" {
  enabled = true  # Enable the CloudFront distribution
  comment = "${var.namespace} - frontend site for mission app"  # Comment for the distribution

  # Origin configuration (define the origin where CloudFront fetches content)
  origin {
    # The domain name of the origin (e.g., an Application Load Balancer)
    domain_name = var.lb_dns_name  # Reference the LB's DNS name from variables
    origin_id   = var.lb_dns_name  # Origin ID (used to uniquely identify the origin)

    custom_origin_config {
      http_port              = 80  # HTTP port for the origin
      https_port             = 443  # HTTPS port for the origin
      origin_protocol_policy = "http-only"  # Only HTTP will be used to fetch from the origin
      origin_ssl_protocols   = ["TLSv1.2"]  # Use TLS 1.2 for secure connections
    }

    # Custom headers to pass to the origin
    custom_header {
      name  = "X-Request"  # Custom header name
      value = var.lb_dns_name  # Custom header value (LB DNS name)
    }
  }

  # Default cache behavior for CloudFront (defines how requests are cached and served)
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]  # Allowed HTTP methods
    cached_methods         = ["GET", "HEAD", "OPTIONS"]  # Methods to cache at the CloudFront edge
    target_origin_id       = var.lb_dns_name  # Target the Load Balancer (origin) by its DNS name
    viewer_protocol_policy = "redirect-to-https"  # Redirect HTTP requests to HTTPS for secure access
    cache_policy_id        = aws_cloudfront_cache_policy.default.id  # Use the default cache policy
  }

  # Geo restrictions (none in this case)
  restrictions {
    geo_restriction {
      restriction_type = "none"  # No geographic restrictions on access
      locations        = []  # Empty list means no specific locations are blocked
    }
  }

  # SSL certificate for HTTPS
  viewer_certificate {
    cloudfront_default_certificate = true  # Use the default CloudFront certificate for HTTPS
  }
}

# CloudFront Cache Policy (defines how CloudFront caches content and forwards requests to the origin)
resource "aws_cloudfront_cache_policy" "default" {
  name        = "${var.namespace}-default-policy"  # Name of the cache policy
  comment     = "Default Policy"  # Description of the policy
  default_ttl = 50  # Default time-to-live (TTL) for cached content (in seconds)
  max_ttl     = 100  # Maximum TTL for cached content (in seconds)
  min_ttl     = 1  # Minimum TTL for cached content (in seconds)

  # Define what data CloudFront includes in cache keys and forwards to the origin
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"  # Include all cookies in cache keys
    }
    headers_config {
      header_behavior = "whitelist"  # Only forward a whitelist of headers to the origin
      headers {
        items = ["X-Request"]  # Whitelist the X-Request header to be forwarded to the origin
      }
    }
    query_strings_config {
      query_string_behavior = "all"  # Include all query strings in cache keys
    }
  }
}
