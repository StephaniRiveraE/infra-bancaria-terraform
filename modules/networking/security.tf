resource "aws_security_group" "rds_sg" {
  name        = "rds-bancario-sg"
  vpc_id      = aws_vpc.vpc_bancaria.id
  description = "Acceso PostgreSQL exclusivo para la red interna"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_bancaria.cidr_block] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "sg-rds-postgres" })
}

# 1. Security Group para el VPC Link (El que hace la petición)
resource "aws_security_group" "apim_vpc_link_sg" {
  name        = "apim-vpc-link-sg"
  vpc_id      = var.vpc_id # Asegúrate de tener esta variable en variables.tf del módulo
  description = "SG asignado al VPC Link del API Gateway"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "sg-apim-link" })
}

# 2. Security Group para el ALB/Backend (El que recibe la petición)
resource "aws_security_group" "backend_sg" {
  name        = "backend-internal-sg"
  vpc_id      = var.vpc_id
  description = "SG para el Load Balancer Interno y Fargate"

  # REGLA DE ORO: Solo acepta tráfico del VPC Link
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.apim_vpc_link_sg.id]
    description     = "Acceso exclusivo desde API Gateway"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "sg-backend-internal" })
}