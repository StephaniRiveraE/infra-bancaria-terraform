# ============================================================================
# ROUTING - Route Tables, NAT Gateway (condicional)
# ============================================================================

# NAT Gateway y EIP - SOLO cuando EKS está habilitado (ahorra ~$1-3/día)
resource "aws_eip" "nat_eip" {
  count  = var.eks_enabled ? 1 : 0
  domain = "vpc"
  tags   = merge(var.common_tags, { Name = "nat-static-ip" })
}

resource "aws_nat_gateway" "nat" {
  count         = var.eks_enabled ? 1 : 0
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public_az1.id 
  tags          = merge(var.common_tags, { Name = "main-nat-gateway" })

  depends_on = [aws_internet_gateway.igw]
}

# Route Table Pública - Siempre necesaria
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_bancaria.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.common_tags, { Name = "public-route-table" })
}

# Route Table Privada - La ruta NAT es condicional
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc_bancaria.id

  # Solo agregar ruta a NAT si EKS está habilitado
  dynamic "route" {
    for_each = var.eks_enabled ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat[0].id
    }
  }

  tags = merge(var.common_tags, { Name = "private-route-table" })
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_rt.id
}