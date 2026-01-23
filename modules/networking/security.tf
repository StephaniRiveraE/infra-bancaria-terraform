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