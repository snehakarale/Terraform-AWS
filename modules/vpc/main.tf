# VPC

# Creates the VPC
resource "aws_vpc" "default" {
  cidr_block           = local.vpc.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.namespace}-vpc"
  }
}

# Creates the Public Subnets
resource "aws_subnet" "public" {

  # for_each: creates a subnet for each AZ & for: converts list of azs (local.vpc.azs) into a map
  for_each = { for index, az_name in local.vpc.azs : index => az_name }

  # VPC ID where the subnet will be created
  vpc_id = aws_vpc.default.id
  # CIDR block for the subnet, dynamically calculated based on the AZ index
  cidr_block = cidrsubnet(aws_vpc.default.cidr_block, 8, (each.key + (length(local.vpc.azs) * 0)))
  # Assign AZ to each subnet 
  availability_zone = each.value
  # Automatically assign a public IP to instances launched in this subnet
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.namespace}-subnet-public-${each.key}"
  }
}

# Creates the Private Subnets
resource "aws_subnet" "private" {

  for_each = { for index, az_name in local.vpc.azs : index => az_name }

  vpc_id     = aws_vpc.default.id
  cidr_block = cidrsubnet(aws_vpc.default.cidr_block, 8, (each.key + (length(local.vpc.azs) * 1)))
  #The offset (length(local.vpc.azs) * 1) is used to shift the starting point for the private subnets so that their CIDR blocks do not overlap with the public subnets.
  availability_zone = each.value

  tags = {
    Name = "${var.namespace}-subnet-private-${each.key}"
  }
}

# Similar to private subnets but intended for instances that need internet access via a NAT Gateway.
resource "aws_subnet" "private_ingress" {

  for_each = { for index, az_name in local.vpc.azs : index => az_name }

  vpc_id            = aws_vpc.default.id
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, (each.key + (length(local.vpc.azs) * 2)))
  availability_zone = each.value

  tags = {
    Name = "${var.namespace}-subnet-private_ingress-${each.key}"
  }
}

# Creates an Internet Gateway to provide public internet access to the VPC.
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${var.namespace}-internet-gateway"
  }
}

# Create route table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  # Create route: to allow internet access via Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"                     # Allow all traffic
    gateway_id = aws_internet_gateway.default.id # Send traffic to Internet Gateway
  }

  tags = {
    Name = "${var.namespace}-route-table-public"
  }
}

# Create route table for Private Subnet
resource "aws_route_table" "private_ingress" {
  # The number of route tables to be created is determined by the number of private ingress subnets
  count = length(aws_subnet.private_ingress)

  # The VPC where the route table will be created
  vpc_id = aws_vpc.default.id

  # Defining a route within the route table
  route {
    # The route sends traffic destined for "0.0.0.0/0" (i.e., all external traffic)
    # to a NAT gateway. This allows instances in the private subnets to access the internet.
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.default[count.index].id # Route to the NAT Gateway
  }

  # Tags to label the route table
  tags = {
    Name = "${var.namespace}-route-table-private-ingress-${count.index}"
  }
}

# aws_main_route_table_association: Associates the default route table (public) with the VPC.
resource "aws_main_route_table_association" "default" {
  vpc_id         = aws_vpc.default.id
  route_table_id = aws_route_table.public.id
}

# aws_route_table_association (public): Associates the public subnets with the public route table.
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# aws_route_table_association (private_ingress): Associates private subnets with their respective private route table.
resource "aws_route_table_association" "private_ingress" {
  count = length(aws_subnet.private_ingress)

  subnet_id      = aws_subnet.private_ingress[count.index].id
  route_table_id = aws_route_table.private_ingress[count.index].id
}


# aws_eip (Elastic IP for NAT Gateway): Creates Elastic IPs (EIPs) for each NAT Gateway, enabling internet access for instances in private subnets.
resource "aws_eip" "nat_gateway" {
  count = length(aws_subnet.public)

  tags = {
    Name = "${var.namespace}-private_ingress-nat-gateway-eip-${count.index}"
  }
}

#aws_nat_gateway: Creates the NAT Gateway in each public subnet, providing internet access to instances in private subnets. The NAT Gateway uses the Elastic IPs created earlier.
resource "aws_nat_gateway" "default" {
  count = length(aws_subnet.public)

  connectivity_type = "public"
  subnet_id         = aws_subnet.public[count.index].id
  allocation_id     = aws_eip.nat_gateway[count.index].id
  depends_on        = [aws_internet_gateway.default]

  tags = {
    Name = "${var.namespace}-private_ingress-nat-gateway-${count.index}"
  }
}