provider "aws" {
  region = "us-east-1"
}

# 1. Lanzamiento de una instancia mediante EC2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "credit_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  tags = {
    Name = "AWS-Credits-Activity"
  }
}

# 2. Configuración de un presupuesto de costes con AWS Budgets
resource "aws_budgets_budget" "credit_budget" {
  name              = "Monthly-Budget-Credits"
  budget_type       = "COST"
  limit_amount      = "10"
  limit_unit        = "USD"
  time_period_start = "2026-02-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["test@example.com"]
  }
}

output "instance_id" {
  value = aws_instance.credit_instance.id
}
