resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.eks_cluster_name}-public-${count.index + 1}"
  }
}


resource "aws_subnet" "private_subnets" {
  count                   = length(var.private_subnet_cidr)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.private_subnet_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.eks_cluster_name}-private-${count.index + 1}"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "eks_vpc_internet_gw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.eks_cluster_name}-internet-gw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "eip_nat" {
  count  = length(var.public_subnet_cidr)
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.public_subnet_cidr)
  allocation_id = aws_eip.eip_nat[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = {
    Name = "${var.eks_cluster_name}-nat-gw-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id

  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_vpc_internet_gw.id
  }

  tags = {
    Name = "${var.eks_cluster_name}-public-route-table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.eks_vpc.id
  count  = length(var.private_subnet_cidr)

  route = {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    Name = "${var.eks_cluster_name}-private-route-table-${count.index + 1}"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidr)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
