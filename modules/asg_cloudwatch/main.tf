# Create Launch Template Configuration for Mission App Instances
resource "aws_launch_template" "mission_app_lc" {
  name_prefix = "${var.namespace}-mission_app_iac_lc-"  # Prefix for the launch template name
  
  # Specify the AMI to be used for EC2 instances
  # image_id = aws_ami_copy.mission_app_ami.id
  image_id = "ami-08b5b3a93ed654d19"  # The ID of the AMI to launch EC2 instances with

  instance_type = "t2.micro"  # Instance type for the EC2 instances (t2.micro)

  # Uncomment and modify the below to specify the instance requirements if needed
  # instance_requirements {
  #   memory_mib {
  #     min = local.vm.instance_requirements.memory_mib.min
  #   }
  #   vcpu_count {
  #     min = local.vm.instance_requirements.vcpu_count.min
  #   }

  #   allowed_instance_types = ["t2.micro"]
  #   instance_generations   = local.vm.instance_requirements.instance_generations
  # }

  ebs_optimized = true  # Enable EBS optimization to enhance performance for EBS volumes

  # Uncomment to use a specific security group for the instances
  # vpc_security_group_ids = [aws_security_group.app.id]
  vpc_security_group_ids = var.security_group_app_id  # Security group to be applied to the instances

  # Define IAM instance profile to be used with the EC2 instance
  iam_instance_profile {
    #name = aws_iam_instance_profile.web_hosting.name
    name = var.iam_instance_profile_web_hosting  # Use IAM role from variable
  }

  # Block device mappings for the EC2 instance (defines the root volume configuration)
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true  # Ensure the volume is deleted when the instance is terminated
      encrypted             = true  # Enable encryption for the root EBS volume
    }
  }

  # Enable EC2 instance detailed monitoring
  monitoring {
    enabled = true
  }

  # Configure instance metadata options (for security and access control)
  metadata_options {
    http_endpoint               = "enabled"  # Enable the HTTP endpoint to access instance metadata
    http_put_response_hop_limit = 1  # Limit the number of allowed hops for PUT requests
    http_tokens                 = "required"  # Tokens are required to access instance metadata
    instance_metadata_tags      = "enabled"  # Enable instance metadata tags
  }

  # Specify the user data script to configure the instance upon launch
  # The script is base64-encoded and includes dynamic variables like region and EFS/S3 resources
  user_data = base64encode(templatefile("${path.module}/userdata/staging-wordpress.sh", {
    region     = data.aws_region.current.name,  # AWS region to deploy the instance
    #efs_id    = aws_efs_file_system.mission_app.id,  # Reference to the EFS file system ID
    efs_id = var.efs_id  # EFS ID for the instance configuration
    #s3_bucket = aws_s3_bucket.mission_app.bucket  # Reference to the S3 bucket for the instance configuration
    s3_bucket = var.bucket_name  # S3 bucket name for configuration
  }))

  # Ensure the launch template is updated to the latest version when changes are made
  update_default_version = true
}

# Autoscaling Group Configuration for Mission App Instances
resource "aws_autoscaling_group" "mission_app_asg" {
  name     = "${var.namespace}-asg-mission_app"  # Name of the autoscaling group
  min_size = 1  # Minimum number of EC2 instances in the autoscaling group
  max_size = 2  # Maximum number of EC2 instances in the autoscaling group

  # Subnet(s) in which the autoscaling group should launch instances
  # Uncomment and modify the line below for a dynamic subnet list if needed
  # vpc_zone_identifier = values(aws_subnet.private_ingress)[*].id
  vpc_zone_identifier = var.private_ingress_subnet_id  # Subnet for the ASG instances

  # Target group ARN (the load balancer target group for routing traffic to the instances)
  # Uncomment and modify the line below for a dynamic target group ARN if needed
  # target_group_arns   = [aws_lb_target_group.mission_app.arn]
  target_group_arns = var.lb_target_group_arn  # ARN for the load balancer target group

  # Mixed instance policy: Configures instances from the launch template
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.mission_app_lc.id  # Reference to the launch template ID
        version            = "$Latest"  # Use the latest version of the launch template
      }
    }
  }

  # Ensure that new ASG instances are created before old instances are destroyed
  lifecycle {
    create_before_destroy = true
  }

  # Tagging the instances created by the autoscaling group
  tag {
    key                 = "Name"
    value               = "${var.namespace}-asg-mission_app"  # Name for the autoscaling instances
    propagate_at_launch = true  # Propagate the tag to instances at launch time
  }

  # Uncomment if dependencies need to be specified for ASG creation
  #depends_on = [module.ec2.aws_instance.staging_app, module.db.aws_db_instance.wp_mysql]
}

# Scaling Policy for Autoscaling Group (Scale-out Policy)
resource "aws_autoscaling_policy" "mission_app_scale_out_policy" {
  name                   = "${var.namespace}-out-policy"  # Name of the scale-out policy
  scaling_adjustment     = 1  # Scale-out by increasing instance count by 1
  adjustment_type        = "ChangeInCapacity"  # Adjust the capacity by a specified number
  cooldown               = 300  # Cooldown period (seconds) before the next scaling action
  autoscaling_group_name  = aws_autoscaling_group.mission_app_asg.name  # Reference to the autoscaling group
}

# CloudWatch Alarm for Autoscaling Group Scale-out (Triggered when CPU usage exceeds threshold)
resource "aws_cloudwatch_metric_alarm" "mission_app_scale_out_alarm" {
  alarm_name          = "${var.namespace}-out-alarm"  # Name of the CloudWatch alarm
  comparison_operator = "GreaterThanOrEqualToThreshold"  # Trigger when metric exceeds the threshold
  evaluation_periods  = "2"  # Number of evaluation periods to check
  metric_name         = "CPUUtilization"  # Metric to monitor (CPU utilization)
  namespace           = "AWS/EC2"  # Namespace for the metric
  period              = "60"  # Period in seconds for metric evaluation
  statistic           = "Average"  # Use the average value of the metric
  threshold           = "30"  # Threshold value for CPU utilization (30%)

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.mission_app_asg.name  # Dimension: autoscaling group name
  }

  alarm_description = "This metric monitors EC2 CPU utilization for Mission App ASG"  # Description of the alarm
  alarm_actions     = [aws_autoscaling_policy.mission_app_scale_out_policy.arn]  # Action to take when triggered (scale out)
}

# Scaling Policy for Autoscaling Group (Scale-in Policy)
resource "aws_autoscaling_policy" "mission_app_scale_in_policy" {
  name                   = "${var.namespace}-in-policy"  # Name of the scale-in policy
  scaling_adjustment     = -1  # Scale-in by decreasing instance count by 1
  adjustment_type        = "ChangeInCapacity"  # Adjust the capacity by a specified number
  cooldown               = 180  # Cooldown period (seconds) before the next scaling action
  autoscaling_group_name  = aws_autoscaling_group.mission_app_asg.name  # Reference to the autoscaling group
}

# CloudWatch Alarm for Autoscaling Group Scale-in (Triggered when CPU usage falls below threshold)
resource "aws_cloudwatch_metric_alarm" "mission_app_scale_in_alarm" {
  alarm_name          = "${var.namespace}-in-alarm"  # Name of the CloudWatch alarm
  comparison_operator = "LessThanOrEqualToThreshold"  # Trigger when metric is less than or equal to threshold
  evaluation_periods  = "2"  # Number of evaluation periods to check
  metric_name         = "CPUUtilization"  # Metric to monitor (CPU utilization)
  namespace           = "AWS/EC2"  # Namespace for the metric
  period              = "60"  # Period in seconds for metric evaluation
  statistic           = "Average"  # Use the average value of the metric
  threshold           = "20"  # Threshold value for CPU utilization (20%)

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.mission_app_asg.name  # Dimension: autoscaling group name
  }

  alarm_description = "This metric monitors EC2 CPU utilization for Mission App ASG"  # Description of the alarm
  alarm_actions     = [aws_autoscaling_policy.mission_app_scale_in_policy.arn]  # Action to take when triggered (scale in)
}
