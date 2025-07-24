output "api_url" {
  description = "API Gateway URL for orders endpoint"
  value       = "${aws_api_gateway_deployment.main.invoke_url}/${var.environment}/orders"
}

output "api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "rest_api_id" {
  description = "API Gateway REST API ID (alternative name)"
  value       = aws_api_gateway_rest_api.main.id
}