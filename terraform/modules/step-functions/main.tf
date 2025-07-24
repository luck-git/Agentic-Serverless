# IAM Role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-${var.environment}-step-functions-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-step-functions-role"
  })
}

# IAM Policy for Step Functions
resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${var.project_name}-${var.environment}-step-functions-policy"
  role = aws_iam_role.step_functions_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          var.validator_lambda_arn,
          var.fulfillment_lambda_arn
        ]
      }
    ]
  })
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "order_workflow" {
  name     = "${var.project_name}-${var.environment}-order-processing"
  role_arn = aws_iam_role.step_functions_role.arn
  
  definition = jsonencode({
    Comment = "Order processing workflow"
    StartAt = "ValidateOrder"
    States = {
      ValidateOrder = {
        Type = "Task"
        Resource = var.validator_lambda_arn
        Next = "CheckValidation"
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
            IntervalSeconds = 2
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "ValidationFailed"
          }
        ]
      }
      
      CheckValidation = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.status"
            StringEquals = "VALIDATED"
            Next = "FulfillOrder"
          }
        ]
        Default = "ValidationFailed"
      }
      
      FulfillOrder = {
        Type = "Task"
        Resource = var.fulfillment_lambda_arn
        Next = "CheckFulfillment"
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
            IntervalSeconds = 2
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "FulfillmentFailed"
          }
        ]
      }
      
      CheckFulfillment = {
        Type = "Choice"
        Choices = [
          {
            Variable = "$.status"
            StringEquals = "FULFILLED"
            Next = "OrderCompleted"
          }
        ]
        Default = "FulfillmentFailed"
      }
      
      OrderCompleted = {
        Type = "Pass"
        Result = {
          status = "SUCCESS"
          message = "Order processed successfully"
        }
        End = true
      }
      
      ValidationFailed = {
        Type = "Pass"
        Result = {
          status = "VALIDATION_FAILED"
          message = "Order validation failed"
        }
        End = true
      }
      
      FulfillmentFailed = {
        Type = "Pass"
        Result = {
          status = "FULFILLMENT_FAILED"
          message = "Order fulfillment failed"
        }
        End = true
      }
    }
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-order-processing"
  })
}

# IAM Role for API Gateway
resource "aws_iam_role" "api_gateway_role" {
  name = "${var.project_name}-${var.environment}-api-gateway-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-api-gateway-role"
  })
}

# IAM Policy for API Gateway
resource "aws_iam_role_policy" "api_gateway_policy" {
  name = "${var.project_name}-${var.environment}-api-gateway-policy"
  role = aws_iam_role.api_gateway_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = aws_sfn_state_machine.order_workflow.arn
      }
    ]
  })
}