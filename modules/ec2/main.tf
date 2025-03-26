# Create an EC2 instance for the staging application
resource "aws_instance" "staging_app" {

  # Lifecycle block to control resource behavior during updates or deletion
  lifecycle {
    prevent_destroy = false  # Allow the instance to be destroyed if needed
    ignore_changes  = [iam_instance_profile, tags, tags_all]  # Ignore changes to IAM profile and tags to prevent unnecessary updates
  }

  ami           = data.aws_ami.linux.image_id  # The AMI (Amazon Machine Image) to use for the instance (from data source)
  instance_type = local.vm.instance_type  # Instance type to use (defined in the local variable `vm.instance_type`)
  
  # Network configuration
  subnet_id                   = var.private_ingress_subnet_1_id  # Subnet ID for the instance (use the first private subnet)
  user_data_replace_on_change = true  # Replace user data when changes occur

  # User data for EC2 instance initialization (staging-efs.sh is a shell script)
  user_data = templatefile("${path.module}/userdata/staging-efs.sh", {
    region = data.aws_region.current.name  # The AWS region the instance is being created in
    efs_id      = var.efs_id  # The ID of the EFS (Elastic File System) to mount
    db_name     = var.db_info["db_name"]  # Database name
    db_username = var.db_info["db_username"]  # Database username
    db_password = var.db_info["db_password"]  # Database password
    db_host     = var.db_info["db_host"]  # Database host address
    DOMAIN_NAME = var.domain_name  # The domain name (from a variable)
    demo_username = local.demo.admin.username  # Demo application admin username
    demo_password = local.demo.admin.password  # Demo application admin password
    demo_email    = local.demo.admin.email  # Demo application admin email
  })

  # IAM instance profile that allows EC2 instance to assume specific roles
  iam_instance_profile   = var.iam_instance_profile  # IAM instance profile to assign to the EC2 instance
  availability_zone      = data.aws_availability_zones.available.names[0]  # Select the first availability zone for the instance
  vpc_security_group_ids = var.security_group_app_id  # Security group for the instance to define network access

  # Instance metadata options to enhance security
  metadata_options {
    http_endpoint               = "enabled"  # Enable metadata endpoint access
    http_put_response_hop_limit = 1  # Limit the response hop count to 1
    http_tokens                 = "required"  # Require the use of IMDSv2 (instance metadata service version 2)
    instance_metadata_tags      = "enabled"  # Enable instance metadata tags
  }

  # Root block device configuration
  root_block_device {
    delete_on_termination = true  # Ensure the root volume is deleted when the instance is terminated
    encrypted             = true  # Encrypt the root block device for data security
  }

  # Tags for the instance (helpful for organization and management)
  tags = {
    Name = format("${var.namespace}-staging_app-%s", element(data.aws_availability_zones.available.names, 0))  # Tag the instance with the application name and availability zone
  }

  # Uncomment if you need to ensure that certain resources are created before this instance
  #depends_on = [aws_s3_object.mission_app-private_key, aws_s3_object.mission_app-public_key]
}

# The following code block is commented out, but it would create an AMI copy if enabled:

# resource "aws_ami_copy" "mission_app_ami" {
#   name              = "Amazon Linux 2 Image"  # Name for the new AMI copy
#   description       = "A copy of ${data.aws_ami.linux.image_id} - ${data.aws_ami.linux.description}"  # Description of the AMI copy
#   source_ami_id     = data.aws_ami.linux.image_id  # The ID of the source AMI
#   source_ami_region = data.aws_region.current.name  # Region where the source AMI exists

#   tags = {
#     Name               = "${var.namespace}-ami"  # Tag with the namespace
#     Description        = data.aws_ami.linux.description  # AMI description
#     "Creation Date"    = data.aws_ami.linux.creation_date  # Creation date of the source AMI
#     "Deprecation Time" = data.aws_ami.linux.deprecation_time  # Deprecation time of the source AMI
#   }
# }
