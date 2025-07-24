# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.environment}-lambda-policy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          "arn:aws:dynamodb:*:*:table/${var.orders_table}",
          "arn:aws:dynamodb:*:*:table/${var.orders_table}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = [
          var.order_queue_arn,
          var.dlq_arn
        ]
      }
    ]
  })
}

# Order Validator Lambda
resource "aws_lambda_function" "order_validator" {
  filename         = "order_validator.zip"
  function_name    = "${var.environment}-order-validator"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = 30
  
  environment {
    variables = {
      ENVIRONMENT     = var.environment
      ORDERS_TABLE    = var.orders_table
      ORDER_QUEUE_URL = var.order_queue_url
    }
  }
  
  depends_on = [aws_iam_role_policy.lambda_policy]
}

# Order Fulfillment Lambda
resource "aws_lambda_function" "order_fulfillment" {
  filename         = "order_fulfillment.zip"
  function_name    = "${var.environment}-order-fulfillment"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = 300
  
  environment {
    variables = {
      ENVIRONMENT  = var.environment
      ORDERS_TABLE = var.orders_table
      DLQ_URL     = var.dlq_url
    }
  }
  
  depends_on = [aws_iam_role_policy.lambda_policy]
}

# Variables
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "orders_table" {
  description = "Orders DynamoDB table name"
  type        = string
}

variable "order_queue_url" {
  description = "Order queue URL"
  type        = string
}

variable "order_queue_arn" {
  description = "Order queue ARN"
  type        = string
}

variable "dlq_url" {
  description = "Dead letter queue URL"
  type        = string
}

variable "dlq_arn" {
  description = "Dead letter queue ARN"
  type        = string
}

# Outputs
output "validator_lambda_arn" {
  value = aws_lambda_function.order_validator.arn
}

output "fulfillment_lambda_arn" {
  value = aws_lambda_function.order_fulfillment.arn
}
