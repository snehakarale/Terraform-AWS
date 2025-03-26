# data source: to gather information about the current region
data "aws_region" "current" {}

# data source: Retrieves the available availability zones (AZs) in the current region. 
data "aws_availability_zones" "available" {
  state = "available"
}

# azs value is used to dynamically select availability zone based on az_num using slice function
locals {
  vpc = {
    azs        = slice(data.aws_availability_zones.available.names, 0, var.az_num) # Select AZs based on az_num
    cidr_block = var.vpc_cidr_block                                                # Set VPC CIDR block
  }
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