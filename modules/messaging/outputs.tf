output "sqs_main_queue_url" {
  description = "URL de la cola principal SQS"
  value       = aws_sqs_queue.switch_transferencias_core.url
}

output "sqs_dlq_url" {
  description = "URL de la Dead Letter Queue"
  value       = aws_sqs_queue.switch_transferencias_dlq.url
}
