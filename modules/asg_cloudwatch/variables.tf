locals {
  vm = {
    instance_type = "t3.micro" # Free tier eligible instance type

    instance_requirements = {
      memory_mib = {
        min = 1024 # 1 GiB memory for t3.micro
      }
      vcpu_count = {
        min = 1 # t3.micro has 1 vCPU
      }
      instance_generations = ["current"] # Current generation instances
    }
  }

}

data "aws_region" "current" {}

variable "namespace" {
  type = string
}

# variable "ami_copy_image_id" {
#   type = string
# }

variable "security_group_app_id" {
  type = list(string)
}

variable "iam_instance_profile_web_hosting" {
  type = string
}

variable "efs_id" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "lb_target_group_arn" {

}

variable "private_ingress_subnet_id" {

}