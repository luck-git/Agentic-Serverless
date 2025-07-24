# Data source for current AWS region
data "aws_region" "current" {}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name = "${var.project_name}-${var.environment}-api"
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-api"
  })
}

# Orders resource
resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "orders"
}

# POST method for orders
resource "aws_api_gateway_method" "post_order" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration with Step Functions
resource "aws_api_gateway_integration" "step_functions_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.post_order.http_method
  
  integration_http_method = "POST"
  type                   = "AWS"
  uri                    = "arn:aws:apigateway:${data.aws_region.current.name}:states:action/StartExecution"
  credentials            = var.lambda_invoke_role
  
  request_templates = {
    "application/json" = jsonencode({
      stateMachineArn = var.step_function_arn
      input          = "$util.escapeJavaScript($input.json('$'))"
    })
  }
}

# Method response
resource "aws_api_gateway_method_response" "post_order_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.post_order.http_method
  status_code = "200"
  
  response_models = {
    "application/json" = "Empty"
  }
}

# Integration response
resource "aws_api_gateway_integration_response" "post_order_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
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

# API deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_integration.step_functions_integration,
    aws_api_gateway_integration_response.post_order_200
  ]
  
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.environment
}