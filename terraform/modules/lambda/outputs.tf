output "validator_lambda_arn" {
  description = "ARN of the order validator Lambda function"
  value       = aws_lambda_function.order_validator.arn
}

output "fulfillment_lambda_arn" {
  description = "ARN of the order fulfillment Lambda function"
  value       = aws_lambda_function.order_fulfillment.arn
}

output "validator_lambda_name" {
  description = "Name of the order validator Lambda function"
  value       = aws_lambda_function.order_validator.function_name
}

output "fulfillment_lambda_name" {
  description = "Name of the order fulfillment Lambda function"
  value       = aws_lambda_function.order_fulfillment.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "validator_lambda_invoke_arn" {
  description = "Invoke ARN of the order validator Lambda function"
  value       = aws_lambda_function.order_validator.invoke_arn
}

output "fulfillment_lambda_invoke_arn" {
  description = "Invoke ARN of the order fulfillment Lambda function"
  value       = aws_lambda_function.order_fulfillment.invoke_arn
}