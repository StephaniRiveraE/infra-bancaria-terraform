
resource "aws_elasticache_subnet_group" "redis" {
  count       = var.elasticache_enabled ? 1 : 0
  name        = "redis-subnet-group"
  description = "Subnet group para cluster Redis del Switch en subnets privadas"
  subnet_ids  = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "redis-subnet-group"
  })
}

resource "aws_security_group" "redis_sg" {
  count       = var.elasticache_enabled ? 1 : 0
  name        = "redis-sg"
  description = "Security Group para ElastiCache Redis del Switch"
  vpc_id      = var.vpc_id

  ingress {
    description = "Redis desde VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "redis-sg"
  })
}



resource "aws_elasticache_cluster" "switch_redis" {
  count = var.elasticache_enabled ? 1 : 0

  cluster_id           = "switch-redis-cache"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  port                 = 6379
  parameter_group_name = "default.redis7"

  subnet_group_name  = aws_elasticache_subnet_group.redis[0].name
  security_group_ids = [aws_security_group.redis_sg[0].id]

  snapshot_retention_limit = 0 

  tags = merge(var.common_tags, {
    Name   = "switch-redis-cache"
    Entity = "Switch"
    Phase  = "2-Persistence"
    Usage  = "Cache de transacciones interbancarias"
  })
}
