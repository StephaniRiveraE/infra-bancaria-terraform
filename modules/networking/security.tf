resource "aws_security_group" "rds_sg" {
  name        = "rds-bancario-sg"
  description = "Security Group para RDS Bancario"
  vpc_id      = aws_vpc.vpc_bancaria.id

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

resource "aws_security_group" "apim_vpc_link_sg" {
  name        = "apim-vpc-link-sg"
  vpc_id      = aws_vpc.vpc_bancaria.id
  description = "Permite al API Gateway salir a buscar al backend"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "sg-apim-vpc-link" })
}

resource "aws_security_group" "backend_sg" {
  name        = "backend-internal-sg"
  vpc_id      = aws_vpc.vpc_bancaria.id
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
