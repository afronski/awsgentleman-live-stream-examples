resource "aws_vpc" "main" {
  cidr_block = var.vpc_CIDR

  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = var.name
  }
}

resource "aws_default_route_table" "main_route_table" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  tags = {
    Name = format("%s-main-route-table", var.name)
  }
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnets_CIDRs)

  vpc_id = aws_vpc.main.id

  cidr_block      = element(var.public_subnets_CIDRs, count.index)
  ipv6_cidr_block = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + 1)

  availability_zone = element(var.zones_for_public_subnets, count.index)

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags = {
    Name = format("%s-public-subnet-%d", var.name, count.index)
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnets_CIDRs)

  vpc_id = aws_vpc.main.id

  cidr_block      = element(var.private_subnets_CIDRs, count.index)
  ipv6_cidr_block = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + length(var.public_subnets_CIDRs) + 1)

  availability_zone = element(var.zones_for_private_subnets, count.index)

  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = false

  tags = {
    Name = format("%s-private-subnet-%d", var.name, count.index)
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = format("%s-internet-gateway", var.name)
  }
}

resource "aws_eip" "nat_gateway_ip" {
  count = length(var.private_subnets_CIDRs)

  tags = {
    Name = format("%s-nat-gateway-ip-%d", var.name, count.index)
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count = length(var.zones_for_private_subnets)

  allocation_id = element(aws_eip.nat_gateway_ip.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)

  depends_on = [aws_internet_gateway.internet_gateway]

  tags = {
    Name = format("%s-nat-gateway-%d", var.name, count.index)
  }
}

resource "aws_egress_only_internet_gateway" "nat_gateway_ipv6" {
  vpc_id = aws_vpc.main.id

  # FIXME: We need to wait for Terraform to support tagging for this resource.
  # https://github.com/terraform-providers/terraform-provider-aws/issues/11563
  #
  # tags = {
  #   Name = format("%s-egress-only-internet-gateway", var.name)
  # }
}

# We create a public Route Table with IGW.

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = format("%s-public-route-table", var.name)
  }
}

resource "aws_route" "internet_gateway_route" {
  route_table_id = aws_route_table.public_route_table.id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route" "internet_gateway_route_ipv6" {
  route_table_id = aws_route_table.public_route_table.id

  destination_ipv6_cidr_block = "::/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "public_route_table_to_public_subnets_association" {
  count = length(var.public_subnets_CIDRs)

  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

# We create additional security group that allows us to SSH to the machines in the private subnets.

resource "aws_security_group" "security_group_for_ssh_from_public_to_private" {
  name        = "security_group_for_ssh_from_public_to_private"
  description = "Allow SSH access to the private subnet from the public one"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8
    to_port     = 8
    protocol    = "icmp"
    cidr_blocks = aws_subnet.public_subnet.*.cidr_block
  }

  ingress {
    from_port        = 8
    to_port          = 8
    protocol         = "icmp"
    ipv6_cidr_blocks = aws_subnet.public_subnet.*.ipv6_cidr_block
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = aws_subnet.public_subnet.*.cidr_block
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    ipv6_cidr_blocks = aws_subnet.public_subnet.*.ipv6_cidr_block
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = aws_subnet.public_subnet.*.cidr_block
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = aws_subnet.public_subnet.*.ipv6_cidr_block
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = aws_subnet.public_subnet.*.cidr_block
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = aws_subnet.public_subnet.*.ipv6_cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = format("%s-security-group-allowing-ssh-access-from-private-subnets-to-public", var.name)
  }
}

# Now, as we want highly available NAT gateways,
# we need to create separate Route Tables for each private subnet.

resource "aws_route_table" "private_route_table" {
  count = length(var.zones_for_private_subnets)

  vpc_id = aws_vpc.main.id

  tags = {
    Name = format("%s-private-route-table-%d", var.name, count.index)
  }
}

resource "aws_route" "nat_gateway_route" {
  count = length(aws_route_table.private_route_table)

  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat_gateway.*.id, count.index)
}

resource "aws_route" "nat_gateway_route_ipv6" {
  count = length(aws_route_table.private_route_table)

  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)

  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.nat_gateway_ipv6.id
}

resource "aws_route_table_association" "private_route_table_to_private_subnets_association" {
  count = length(aws_route_table.private_route_table)

  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}
