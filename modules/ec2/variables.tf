data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {

  vpc = {
    azs        = slice(data.aws_availability_zones.available.names, 0, var.az_num)
    cidr_block = var.vpc_cidr_block
  }

  vm = {
    instance_type = "t2.micro"

    # instance_requirements = {
    #   memory_mib = {
    #     min = 8192
    #   }
    #   vcpu_count = {
    #     min = 2
    #   }
    #   instance_generations = ["current"]
    # }
  }

  demo = {
    admin = {
      username = "wpadmin"
      password = "wppassword"
      email    = "admin@demo.com"
    }
  }
}

data "aws_ami" "linux" {
  owners      = ["amazon"]
  most_recent = true
  name_regex  = "^al2023-ami-2023\\..*"

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

variable "db_info" {
  description = "A map containing the RDS database information (name, username, password, host)"
  type        = map(string)
}

variable "security_group_app_id" {
  type = list(string)
}

variable "efs_id" {
  type = string
}

variable "private_ingress_subnet_1_id" {
  type = string
}

variable "domain_name" {
  type = string
}
variable "az_num" {
  type = number
}

variable "namespace" {
  type = string
}

variable "vpc_cidr_block" {
  type = string

}

variable "iam_instance_profile" {
  type = string
}