variable "namespace" {
  type = string
}

variable "vpc_id" {
  type = string
}


variable "private_subnet_cidr_block" {
  type = list(string)
}

variable "private_ingress_subnet_cidr_block" {
  type = list(string)
}

variable "private_ingress_subnet_id" {
  type = list(string)
}