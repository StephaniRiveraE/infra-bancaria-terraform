# ============================================================================
# AMAZON MQ - RABBITMQ BROKER
# Servidor de colas para comunicación entre bancos (versión académica ~$25/mes)
# ============================================================================

# Generar contraseña segura para el admin de RabbitMQ
resource "random_password" "rabbitmq_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*+-=?^_"
}

# Security Group para Amazon MQ (RabbitMQ)
resource "aws_security_group" "rabbitmq_sg" {
  name        = "rabbitmq-broker-sg"
  vpc_id      = var.vpc_id
  description = "Security group para Amazon MQ RabbitMQ - acceso publico para bancos externos"

  # Puerto AMQPS (conexión segura desde microservicios)
  ingress {
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "AMQPS - Conexion segura para microservicios"
  }

  # Puerto de consola web de RabbitMQ
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Consola web de administracion RabbitMQ"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name      = "sg-rabbitmq-broker"
    Component = "Messaging"
  })
}

# Broker de Amazon MQ (RabbitMQ)
resource "aws_mq_broker" "rabbitmq" {
  broker_name = "switch-rabbitmq"

  engine_type         = "RabbitMQ"
  engine_version      = "3.13"
  host_instance_type  = "mq.t3.micro"
  deployment_mode     = "SINGLE_INSTANCE"
  publicly_accessible = true

  # Usuario administrador
  user {
    username = "mqadmin"
    password = random_password.rabbitmq_password.result
  }

  # Red - usa una subnet pública para acceso externo
  subnet_ids         = [var.public_subnet_id]
  security_groups    = [aws_security_group.rabbitmq_sg.id]

  # Mantenimiento automático (domingos 3-4 AM)
  maintenance_window_start_time {
    day_of_week = "SUNDAY"
    time_of_day = "03:00"
    time_zone   = "America/Guayaquil"
  }

  # Logs
  logs {
    general = true
  }

  tags = merge(var.common_tags, {
    Name      = "switch-rabbitmq"
    Component = "Messaging"
    Layer     = "Message-Broker"
  })
}

# Guardar credenciales en Secrets Manager
resource "aws_secretsmanager_secret" "rabbitmq_credentials" {
  name        = "rabbitmq-credentials"
  description = "Credenciales de acceso al broker RabbitMQ para el Switch"

  recovery_window_in_days = 7

  tags = merge(var.common_tags, {
    Component = "Messaging"
  })
}

resource "aws_secretsmanager_secret_version" "rabbitmq_credentials" {
  secret_id = aws_secretsmanager_secret.rabbitmq_credentials.id

  secret_string = jsonencode({
    username     = "mqadmin"
    password     = random_password.rabbitmq_password.result
    broker_id    = aws_mq_broker.rabbitmq.id
    console_url  = "https://${aws_mq_broker.rabbitmq.instances[0].console_url}"
    amqps_url    = "amqps://${aws_mq_broker.rabbitmq.instances[0].endpoints[0]}"
  })
}
