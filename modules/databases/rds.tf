resource "random_password" "db_passwords" {
  for_each         = toset(keys(var.entidades))
  length           = 16
  special          = true
  override_special = "!#$%&*+-=?^_"
}

/*
resource "aws_db_instance" "rds_instances" {
  for_each = var.entidades

  identifier        = "rds-${each.key}-v3"
  allocated_storage = var.rds_storage_gb
  db_name           = each.value
  engine            = "postgres"
  engine_version    = var.rds_engine_version
  instance_class    = var.rds_instance_class

  username = var.rds_username
  password = random_password.db_passwords[each.key].result

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_security_group_id]

  publicly_accessible = false
  storage_encrypted   = true
  skip_final_snapshot = true

  # Ignorar cambios que causan errores cuando RDS está stopped
  # AWS no permite modificar RDS en estado stopped
  # lifecycle block removido para permitir la recreación y sincronización de red


  tags = merge(var.common_tags, {
    Name   = "rds-${each.key}"
    Entity = title(each.key)
  })
}
*/
resource "aws_secretsmanager_secret" "db_secrets" {
  for_each    = var.entidades
  name        = "rds-secret-${each.key}-v2"
  description = "Credenciales maestras para la instancia RDS de ${each.key}"

  recovery_window_in_days = 7

  tags = merge(var.common_tags, {
    Domain = title(each.key)
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  for_each  = aws_secretsmanager_secret.db_secrets
  secret_id = each.value.id

  secret_string = jsonencode({
    username = var.rds_username
    password = random_password.db_passwords[each.key].result
    engine   = "postgres"
    host     = aws_db_instance.rds_instances[each.key].address
    port     = 5432
    db_name  = aws_db_instance.rds_instances[each.key].db_name
  })
}