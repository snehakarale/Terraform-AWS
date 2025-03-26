variable "namespace" {
  type = string
}

variable "private_subnet_id" {
  type = list(string)
}

variable "security_group_db_id" {
  type = list(string)
}

locals {
  rds = {
    engine         = "mysql"
    engine_version = "8.0.35"
    instance_class = "db.t3.micro"
    db_name        = "mydb"
    username       = "dbuser123"
  }
}