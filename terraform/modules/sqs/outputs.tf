output "order_queue_url" {
  description = "URL of the main order processing queue"
  value       = aws_sqs_queue.order_queue.url
}

output "order_queue_arn" {
  description = "ARN of the main order processing queue"
  value       = aws_sqs_queue.order_queue.arn
}

output "order_queue_name" {
  description = "Name of the main order processing queue"
  value       = aws_sqs_queue.order_queue.name
}

output "dlq_url" {
  description = "URL of the dead letter queue"
  value       = aws_sqs_queue.order_dlq.url
}

output "dlq_arn" {
  description = "ARN of the dead letter queue"
  value       = aws_sqs_queue.order_dlq.arn
}

output "dlq_name" {
  description = "Name of the dead letter queue"
  value       = aws_sqs_queue.order_dlq.name
}