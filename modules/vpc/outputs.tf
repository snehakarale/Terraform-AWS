output "vpc_id" {
  value = aws_vpc.default.id
}

output "private_subnet_cidr_block" {
  value = values(aws_subnet.private)[*].cidr_block
}

output "private_ingress_subnet_cidr_block" {
  value = values(aws_subnet.private_ingress)[*].cidr_block
}

output "private_ingress_subnet_id" {
  value = values(aws_subnet.private_ingress)[*].id
}

output "private_subnet_id" {
  value = values(aws_subnet.private)[*].id
}

output "az_list" {
  value = local.vpc.azs
}

output "private_ingress_subnet_1_id" {
  value = aws_subnet.private_ingress[0].id
}