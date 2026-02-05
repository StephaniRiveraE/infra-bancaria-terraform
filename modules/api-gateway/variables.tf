variable "project_name" { type = string }
variable "environment" { type = string }
variable "common_tags" { type = map(string) }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

variable "backend_security_group_id" { type = string }
variable "apim_vpc_link_security_group_id" { type = string }

variable "cognito_endpoint" { type = string }
variable "cognito_client_ids" { type = list(string) }
variable "internal_secret_value" { type = string }

variable "apim_backend_port" {
  type    = number
  default = 8080
}

variable "apim_enable_custom_domain" {
  type    = bool
  default = false
}

variable "apim_domain_name" {
  type    = string
  default = ""
}

variable "apim_acm_certificate_arn" {
  type    = string
  default = ""
}

variable "apim_log_retention_days" {
  description = "Days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "apim_alarm_sns_topic_arn" {
  description = "SNS Topic ARN for CloudWatch Alarms"
  type        = string
  default     = ""
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}
