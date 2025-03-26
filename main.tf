# IAM Module: Responsible for managing IAM roles and policies that will be applied to resources
module "iam" {
  source = "./modules/iam"
}

# VPC Module: Creates the Virtual Private Cloud (VPC) and manages networking resources like subnets and routes
module "vpc" {
  source         = "./modules/vpc"
  az_num         = var.az_num  # Number of availability zones to use
  namespace      = "terraform-workshop"  # Namespace for the VPC
  vpc_cidr_block = var.vpc_cidr_block  # CIDR block for the VPC
}

# Security Group Module: Configures security groups to manage access and traffic filtering
module "sg" {
  source                            = "./modules/sg"
  namespace                         = "terraform-workshop"
  vpc_id                            = module.vpc.vpc_id  # Security group associated with the VPC
  private_subnet_cidr_block         = module.vpc.private_subnet_cidr_block  # CIDR block for private subnets
  private_ingress_subnet_cidr_block = module.vpc.private_ingress_subnet_cidr_block  # CIDR block for ingress subnet
  private_ingress_subnet_id         = module.vpc.private_ingress_subnet_id  # Subnet ID for the ingress
  depends_on                        = [module.vpc]  # Wait for VPC creation
}

# Database Module: Manages database resources
module "db" {
  source               = "./modules/db"
  namespace            = "terraform-workshop"
  private_subnet_id    = module.vpc.private_subnet_id  # Subnet for database
  security_group_db_id = module.sg.security_group_db_id  # Security group for the DB
  depends_on           = [module.sg, module.vpc]  # Ensure SG and VPC are created before DB
}

# EFS Module: Creates and configures an Elastic File System (EFS) for storage
module "efs" {
  source                    = "./modules/efs"
  namespace                 = "terraform-workshop"
  az_list                   = module.vpc.az_list  # Availability zones for EFS
  private_ingress_subnet_id = module.vpc.private_ingress_subnet_id  # Subnet for EFS
  security_group_nfs_id     = module.sg.security_group_nfs_id  # Security group for NFS
  depends_on                = [module.sg, module.vpc]  # Wait for SG and VPC
}

# S3 Module: Creates an S3 bucket for object storage
module "s3" {
  source    = "./modules/s3"
  namespace = "terraform-workshop"
}

# Load Balancer with TLS Module: Configures a load balancer with TLS 
module "lb_tls" {
  source                = "./modules/lb_tls"
  namespace             = "terraform-workshop"
  private_subnet_id     = module.vpc.private_subnet_id  # Subnet for the load balancer
  vpc_id                = module.vpc.vpc_id  # VPC for the LB
  security_group_app_id = module.sg.security_group_app_id  # Security group for app
  bucket_name           = module.s3.bucket_name  # S3 bucket for TLS certs (if used)
  depends_on            = [module.vpc, module.sg, module.s3]  # Wait for VPC, SG, and S3
}

# EC2 Module: Manages the creation and configuration of EC2 instances
module "ec2" {
  source    = "./modules/ec2"
  namespace = "terraform-workshop"
  db_info = {
    db_name     = module.db.db_name  # DB connection details for EC2
    db_username = module.db.db_username
    db_password = module.db.db_password
    db_host     = module.db.db_host
  }
  private_ingress_subnet_1_id = module.vpc.private_ingress_subnet_1_id  # Subnet for EC2
  security_group_app_id       = module.sg.security_group_app_id  # Security group for EC2
  domain_name                 = module.cloudfront.domain_name  # Domain name for application
  efs_id                      = module.efs.efs_id  # EFS ID to attach to EC2 instances
  az_num                      = var.az_num  # Number of AZs for EC2
  vpc_cidr_block              = var.vpc_cidr_block  # CIDR block for EC2 networking
  iam_instance_profile        = module.iam.iam_instance_profile_app  # IAM profile for EC2
  depends_on                  = [module.vpc, module.sg, module.efs, module.iam, module.s3.aws_s3_object]  # Wait for dependencies
}

# Autoscaling and CloudWatch Module: Configures auto-scaling for EC2 instances with CloudWatch alarms
module "asg_cloudwatch" {
  source                           = "./modules/asg_cloudwatch"
  namespace                        = "terraform-workshop"
  security_group_app_id            = module.sg.security_group_app_id  # SG for autoscaling
  iam_instance_profile_web_hosting = module.iam.iam_instance_profile_web_hosting  # IAM profile for web hosting
  efs_id                           = module.efs.efs_id  # EFS for scaling instances
  bucket_name                      = module.s3.bucket_name  # S3 bucket for scaling resources
  private_ingress_subnet_id        = module.vpc.private_ingress_subnet_id  # Subnet for scaling
  lb_target_group_arn              = module.lb_tls.lb_target_group_arn  # Target group for scaling
  depends_on = [module.ec2.aws_instance]  # Wait for EC2 instance creation
}

# CloudFront Module: Configures CloudFront for content delivery and caching.
module "cloudfront" {
  source = "./modules/cloudfront"
  namespace = "terraform-workshop"
  lb_dns_name = module.lb_tls.lb_dns_name  # Load balancer DNS for CloudFront
  depends_on = [module.lb_tls.aws_lb]  # Wait for LB before setting up CloudFront
}
