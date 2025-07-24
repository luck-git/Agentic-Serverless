# Dead Letter Queue
resource "aws_sqs_queue" "order_dlq" {
  name = "${var.project_name}-${var.environment}-order-dlq"
  
  message_retention_seconds = 1209600 # 14 days
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-order-dlq"
    Type = "DeadLetterQueue"
  })
}

# Main Order Queue
resource "aws_sqs_queue" "order_queue" {
  name = "${var.project_name}-${var.environment}-order-queue"
  
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = 1209600
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-order-queue"
    Type = "OrderQueue"
  })
}