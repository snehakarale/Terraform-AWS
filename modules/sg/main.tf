# Get the current AWS region
data "aws_region" "current" {}

# Create a Security Group for NFS (Network File System)
resource "aws_security_group" "nfs" {
  name_prefix = "${var.namespace}-nfs-"  # Prefix for security group name
  vpc_id      = var.vpc_id              # VPC ID to associate the security group with

  # Ingress rule to allow NFS traffic from private subnets on port 2049 (NFS)
  ingress {
    description = "Allow any NFS traffic from private subnets"
    cidr_blocks = concat(var.private_subnet_cidr_block, var.private_ingress_subnet_cidr_block)
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
  }

  # Egress rule to allow all outbound traffic from this security group
  egress {
    description      = "Allow all outbound traffic"
    cidr_blocks      = ["0.0.0.0/0"]   # Allows traffic to any IP
    ipv6_cidr_blocks = ["::/0"]         # Allows IPv6 traffic to any address
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  # -1 allows all protocols
  }
}

# Create a Security Group for application servers
resource "aws_security_group" "app" {
  name_prefix = "${var.namespace}-app-"  # Prefix for security group name
  vpc_id      = var.vpc_id              # VPC ID to associate the security group with

  # Ingress rule to allow HTTP traffic (port 80) from any IP
  ingress {
    description = "Allow HTTP from any IP"
    cidr_blocks = ["0.0.0.0/0"]  # Allows traffic from any IP address
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  # Ingress rule to allow HTTPS traffic (port 443) from any IP
  ingress {
    description = "Allow HTTPS from any IP"
    cidr_blocks = ["0.0.0.0/0"]  # Allows traffic from any IP address
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  # Egress rule to allow all outbound traffic from this security group
  egress {
    description      = "Allow all outbound traffic"
    cidr_blocks      = ["0.0.0.0/0"]   # Allows traffic to any IP
    ipv6_cidr_blocks = ["::/0"]         # Allows IPv6 traffic to any address
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  # -1 allows all protocols
  }
}

# Create a Security Group for Database (MySQL) servers
resource "aws_security_group" "db" {
  name_prefix = "${var.namespace}-db-"  # Prefix for security group name
  vpc_id      = var.vpc_id              # VPC ID to associate the security group with

  # Ingress rule to allow MySQL traffic (port 3306) from private subnets
  ingress {
    description = "Allow incoming traffic for MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = concat(var.private_subnet_cidr_block, var.private_ingress_subnet_cidr_block)
  }

  # Egress rule to allow all outbound traffic from this security group
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  # -1 allows all protocols
    cidr_blocks      = ["0.0.0.0/0"]   # Allows traffic to any IP
    ipv6_cidr_blocks = ["::/0"]         # Allows IPv6 traffic to any address
  }
}

# Create a Security Group that allows all incoming and outgoing traffic
resource "aws_security_group" "any" {
  name_prefix = "${var.namespace}-any-"  # Prefix for security group name
  vpc_id      = var.vpc_id              # VPC ID to associate the security group with

  # Ingress rule to allow any incoming traffic (all protocols and ports)
  ingress {
    description      = "Allow any incoming traffic"
    from_port        = 0
    to_port          = 0
    protocol         = -1  # -1 allows all protocols
    cidr_blocks      = ["0.0.0.0/0"]  # Allows traffic from any IP
    ipv6_cidr_blocks = ["::/0"]        # Allows IPv6 traffic from any address
  }

  # Egress rule to allow all outbound traffic (all protocols and ports)
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  # -1 allows all protocols
    cidr_blocks      = ["0.0.0.0/0"]   # Allows traffic to any IP
    ipv6_cidr_blocks = ["::/0"]         # Allows IPv6 traffic to any address
  }
}

# Create VPC Interface Endpoints for different AWS services
resource "aws_vpc_endpoint" "interface" {
  for_each = toset(["ssm", "ssmmessages", "ec2messages", "secretsmanager"])

  vpc_id              = var.vpc_id              # VPC ID to associate the endpoint with
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.key}"  # Service-specific endpoint
  vpc_endpoint_type   = "Interface"  # Type of VPC endpoint (Interface)
  private_dns_enabled = true  # Enable private DNS for the service

  subnet_ids         = var.private_ingress_subnet_id   # Subnet IDs where the endpoint will be placed
  security_group_ids = [aws_security_group.any.id]     # Associate security group with endpoint

  tags = {
    Name = "${var.namespace}-endpoint-${each.key}"  # Tag for the endpoint resource
  }
}

# Create a VPC Gateway Endpoint for S3 service
resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(["s3"])  # Only create gateway endpoint for S3

  vpc_id       = var.vpc_id                # VPC ID to associate the endpoint with
  service_name = "com.amazonaws.${data.aws_region.current.name}.${each.key}"  # S3 service endpoint

  tags = {
    Name = "${var.namespace}-endpoint-${each.key}"  # Tag for the endpoint resource
  }
}
