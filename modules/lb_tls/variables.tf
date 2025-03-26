variable "namespace" {
  type = string
}

variable "private_subnet_id" {
  type = list(string)
}

variable "security_group_app_id" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "bucket_name" {
  type = string
}