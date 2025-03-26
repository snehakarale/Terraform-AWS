# Create an Amazon EFS (Elastic File System) for the application
resource "aws_efs_file_system" "mission_app" {
  creation_token = "${var.namespace}-efs"  # Unique identifier to ensure that the EFS file system is created only once
  encrypted      = true                     # Enable encryption for the file system to protect data at rest

  tags = {
    Name = "${var.namespace}-efs"  # Tag the EFS with the application namespace for easier identification
  }
}

# Create Mount Targets for the EFS in different Availability Zones
resource "aws_efs_mount_target" "mission_app_targets" {
  count = length(var.az_list)  # Create a mount target in each Availability Zone listed in var.az_list

  file_system_id  = aws_efs_file_system.mission_app.id  # Attach the mount target to the created EFS file system
  subnet_id       = var.private_ingress_subnet_id[count.index]  # Use a subnet in each Availability Zone from var.private_ingress_subnet_id
  security_groups = var.security_group_nfs_id  # Associate security groups (NFS security rules) with the mount target
}
