# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"
  
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
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-lambda-role"
  })
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-${var.environment}-lambda-policy"
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
          var.orders_table_arn,
          "${var.orders_table_arn}/index/*"
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
  filename         = "${path.module}/order_validator.zip"
  function_name    = "${var.project_name}-${var.environment}-order-validator"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = var.lambda_timeout
  memory_size     = var.memory_size
  
  environment {
    variables = {
      ENVIRONMENT     = var.environment
      ORDERS_TABLE    = var.orders_table
      ORDER_QUEUE_URL = var.order_queue_url
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-order-validator"
  })
  
  depends_on = [aws_iam_role_policy.lambda_policy]
}

# Order Fulfillment Lambda
resource "aws_lambda_function" "order_fulfillment" {
  filename         = "${path.module}/order_fulfillment.zip"
  function_name    = "${var.project_name}-${var.environment}-order-fulfillment"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = var.lambda_timeout
  memory_size     = var.memory_size
  
  environment {
    variables = {
      ENVIRONMENT  = var.environment
      ORDERS_TABLE = var.orders_table
      DLQ_URL     = var.dlq_url
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-order-fulfillment"
  })
  
  depends_on = [aws_iam_role_policy.lambda_policy]
}