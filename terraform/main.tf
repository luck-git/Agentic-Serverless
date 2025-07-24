terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "order-processing-system"
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Modules
module "dynamodb" {
  source = "./modules/dynamodb"
  
  environment = var.environment
  table_name  = "${var.environment}-orders"
}

module "sqs" {
  source = "./modules/sqs"
  
  environment = var.environment
}

module "lambda" {
  source = "./modules/lambda"
  
  environment     = var.environment
  orders_table    = module.dynamodb.table_name
  order_queue_url = module.sqs.order_queue_url
  dlq_url        = module.sqs.dlq_url
}

module "step_functions" {
  source = "./modules/step-functions"
  
  environment           = var.environment
  validator_lambda_arn  = module.lambda.validator_lambda_arn
  fulfillment_lambda_arn = module.lambda.fulfillment_lambda_arn
}

module "api_gateway" {
  source = "./modules/api-gateway"
  
  environment          = var.environment
  step_function_arn    = module.step_functions.state_machine_arn
  lambda_invoke_role   = module.step_functions.api_gateway_role_arn
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"  # Changed to match your bucket region
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Outputs
output "api_gateway_url" {
  value = module.api_gateway.api_url
}

output "orders_table_name" {
  value = module.dynamodb.table_name
}
