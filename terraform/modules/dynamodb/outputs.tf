output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.orders.name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.orders.arn
}

output "table_stream_arn" {
  description = "DynamoDB stream ARN"
  value       = aws_dynamodb_table.orders.stream_arn
}