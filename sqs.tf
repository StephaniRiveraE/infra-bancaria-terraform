
resource "aws_sqs_queue" "switch_transferencias_dlq" {
  name                        = "switch-transferencias-deadletter.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}

resource "aws_sqs_queue" "switch_transferencias_core" {
  name                        = "switch-transferencias-interbancarias.fifo"
  fifo_queue                  = true
  
  content_based_deduplication = true 
  visibility_timeout_seconds = 60 

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.switch_transferencias_dlq.arn
    maxReceiveCount     = 4
  })

  tags = merge(var.common_tags, {
    ERS_Version  = "1.1"
    Retry_Policy = "Deterministic-4-Attempts"
  })
}