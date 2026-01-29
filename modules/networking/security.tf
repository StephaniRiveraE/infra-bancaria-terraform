variable "vpc_id" {}
variable "vpc_cidr" {}
variable "availability_zones" { type = list(string) }
variable "common_tags" { type = map(string) }

# 1. Security Group para RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-bancario-sg"
  description = "Security Group para RDS Bancario"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL desde VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "rds-bancario-sg"
  })
}

# 2. SG para el VPC Link (Salida del API Gateway)
resource "aws_security_group" "apim_vpc_link_sg" {
  name        = "apim-vpc-link-sg"
  vpc_id      = var.vpc_id
  description = "Permite al API Gateway salir a buscar al backend"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "sg-apim-vpc-link" })
}

# 3. SG para el Backend (Solo acepta tráfico del VPC Link)
resource "aws_security_group" "backend_sg" {
  name        = "backend-internal-sg"
  vpc_id      = var.vpc_id
  description = "Solo acepta trafico del API Gateway"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.apim_vpc_link_sg.id]
  }
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.apim_vpc_link_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "sg-backend-internal" })
}
