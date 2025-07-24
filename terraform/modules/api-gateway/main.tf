resource "aws_api_gateway_rest_api" "order_api" {
  name        = "${var.environment}-order-api"
  description = "Order processing API"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  parent_id   = aws_api_gateway_rest_api.order_api.root_resource_id
  path_part   = "orders"
}

resource "aws_api_gateway_method" "post_order" {
  rest_api_id   = aws_api_gateway_rest_api.order_api.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "step_functions_integration" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.post_order.http_method
  
  integration_http_method = "POST"
  type                   = "AWS"
  uri                    = "arn:aws:apigateway:${data.aws_region.current.name}:states:action/StartExecution"
  credentials            = var.lambda_invoke_role
  
  request_templates = {
    "application/json" = jsonencode({
      stateMachineArn = var.step_function_arn
      input          = "$util.escapeJavaScript($input.json('))"
    })
  }
}

resource "aws_api_gateway_method_response" "post_order_200" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.post_order.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "post_order_200" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.post_order.http_method
  status_code = aws_api_gateway_method_response.post_order_200.status_code
  
  response_templates = {
    "application/json" = jsonencode({
      message = "Order submitted successfully"
      executionArn = "$input.json('$.executionArn')"
    })
  }
  
  depends_on = [aws_api_gateway_integration.step_functions_integration]
}

resource "aws_api_gateway_deployment" "order_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.step_functions_integration,
    aws_api_gateway_integration_response.post_order_200
  ]
  
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  stage_name  = var.environment
}

data "aws_region" "current" {}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "step_function_arn" {
  description = "Step Functions state machine ARN"
  type        = string
}

variable "lambda_invoke_role" {
  description = "IAM role for API Gateway to invoke Step Functions"
  type        = string
}

output "api_url" {
  value = "${aws_api_gateway_deployment.order_api_deployment.invoke_url}/${var.environment}/orders"
}

output "api_id" {
  value = aws_api_gateway_rest_api.order_api.id
}
