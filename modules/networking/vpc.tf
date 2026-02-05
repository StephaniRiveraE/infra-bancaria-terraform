resource "aws_vpc" "vpc_bancaria" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.common_tags, { Name = "vpc-ecosistema-bancario" })
}

resource "aws_subnet" "public_az1" {
  vpc_id            = aws_vpc.vpc_bancaria.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zones[0]
  tags = merge(var.common_tags, {
    Name                     = "public-1a",
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "public_az2" {
  vpc_id            = aws_vpc.vpc_bancaria.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zones[1]
  tags = merge(var.common_tags, {
    Name                     = "public-1b",
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.vpc_bancaria.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = var.availability_zones[0]
  tags = merge(var.common_tags, {
    Name                              = "private-1a",
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.vpc_bancaria.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = var.availability_zones[1]
  tags = merge(var.common_tags, {
    Name                              = "private-1b",
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_bancaria.id
  tags   = { Name = "main-igw" }
}

resource "aws_db_subnet_group" "db_segments" {
  name       = "bancario-db-subnet-group"
  subnet_ids = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]

  tags = merge(var.common_tags, {
    Name = "Main DB Subnet Group"
  })
}