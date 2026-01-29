output "vpc_id" {
  description = "ID de la VPC principal"
  value       = aws_vpc.vpc_bancaria.id
}

output "vpc_cidr_block" {
  description = "CIDR block de la VPC"
  value       = aws_vpc.vpc_bancaria.cidr_block
}

output "public_subnet_az1_id" {
  description = "ID de la subnet pública en AZ1"
  value       = aws_subnet.public_az1.id
}

output "public_subnet_az2_id" {
  description = "ID de la subnet pública en AZ2"
  value       = aws_subnet.public_az2.id
}

output "private_subnet_az1_id" {
  description = "ID de la subnet privada en AZ1"
  value       = aws_subnet.private_az1.id
}

output "private_subnet_az2_id" {
  description = "ID de la subnet privada en AZ2"
  value       = aws_subnet.private_az2.id
}

output "db_subnet_group_name" {
  description = "Nombre del DB subnet group"
  value       = aws_db_subnet_group.db_segments.name
}

output "rds_security_group_id" {
  description = "ID del security group de RDS"
  value       = aws_security_group.rds_sg.id
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.igw.id
}
output "apim_vpc_link_sg_id" {
output "vpc_id" {
  description = "ID de la VPC principal"
  value       = aws_vpc.vpc_bancaria.id
}

output "vpc_cidr_block" {
  description = "CIDR block de la VPC"
  value       = aws_vpc.vpc_bancaria.cidr_block
}

output "public_subnet_az1_id" {
  description = "ID de la subnet pública en AZ1"
  value       = aws_subnet.public_az1.id
}

output "public_subnet_az2_id" {
  description = "ID de la subnet pública en AZ2"
  value       = aws_subnet.public_az2.id
}

output "private_subnet_az1_id" {
  description = "ID de la subnet privada en AZ1"
  value       = aws_subnet.private_az1.id
}

output "private_subnet_az2_id" {
  description = "ID de la subnet privada en AZ2"
  value       = aws_subnet.private_az2.id
}

output "db_subnet_group_name" {
  description = "Nombre del DB subnet group"
  value       = aws_db_subnet_group.db_segments.name
}

output "rds_security_group_id" {
  description = "ID del security group de RDS"
  value       = aws_security_group.rds_sg.id
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.igw.id
}
output "apim_vpc_link_sg_id" {
  value = aws_security_group.apim_vpc_link_sg.id
}

output "backend_sg_id" {
  value = aws_security_group.backend_sg.id
}
# Removed duplicate outputs
