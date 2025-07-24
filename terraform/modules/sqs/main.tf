resource "aws_sqs_queue" "order_dlq" {
  name = "${var.environment}-order-dlq"
  
  message_retention_seconds = 1209600 # 14 days
  
  tags = {
    Name = "${var.environment}-order-dlq"
  }
}

resource "aws_sqs_queue" "order_queue" {
  name = "${var.environment}-order-queue"
  
  visibility_timeout_seconds = 300
  message_retention_seconds  = 1209600
  max_receive_count         = 3
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_dlq.arn
    maxReceiveCount     = 3
  })
  
  tags = {
    Name = "${var.environment}-order-queue"
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

output "order_queue_url" {
  value = aws_sqs_queue.order_queue.url
}

output "order_queue_arn" {
  value = aws_sqs_queue.order_queue.arn
}

output "dlq_url" {
  value = aws_sqs_queue.order_dlq.url
}

output "dlq_arn" {
  value = aws_sqs_queue.order_dlq.arn
}
