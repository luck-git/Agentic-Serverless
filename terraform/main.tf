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
    tags = merge(var.tags, {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    })
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Modules
module "dynamodb" {
  source = "./modules/dynamodb"

  environment                   = var.environment
  project_name                  = var.project_name
  orders_table_name             = coalesce(var.orders_table_name, "${var.project_name}-${var.environment}-orders")
  enable_point_in_time_recovery = var.enable_point_in_time_recovery
  tags                          = local.common_tags
}

module "lambda" {
  source = "./modules/lambda"

  environment      = var.environment
  project_name     = var.project_name
  orders_table     = module.dynamodb.table_name
  orders_table_arn = module.dynamodb.table_arn
  order_queue_url  = module.sqs.order_queue_url
  order_queue_arn  = module.sqs.order_queue_arn
  dlq_url          = module.sqs.dlq_url
  dlq_arn          = module.sqs.dlq_arn
  lambda_timeout   = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  tags             = local.common_tags
}

module "step_functions" {
  source = "./modules/step-functions"

  environment            = var.environment
  project_name           = var.project_name
  validator_lambda_arn   = module.lambda.validator_lambda_arn
  fulfillment_lambda_arn = module.lambda.fulfillment_lambda_arn
  tags                   = local.common_tags
}

module "api_gateway" {
  source = "./modules/api-gateway"

  environment        = var.environment
  project_name       = var.project_name
  step_function_arn  = module.step_functions.state_machine_arn
  lambda_invoke_role = module.step_functions.api_gateway_role_arn
  tags               = local.common_tags
}

module "sqs" {
  source = "./modules/sqs"

  environment        = var.environment
  project_name       = var.project_name
  visibility_timeout = var.sqs_visibility_timeout
  max_receive_count  = var.sqs_max_receive_count
  tags               = local.common_tags
}
module "codepipeline" {
  source        = "./modules/codepipeline"
  project_name  = var.project_name
  environment   = var.environment
 github_owner = data.aws_ssm_parameter.github_owner.value
  github_repo  = data.aws_ssm_parameter.github_repo.value
  github_token = data.aws_ssm_parameter.github_token.value
  tags          = local.common_tags
}
# Outputs
output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_url
}

output "orders_table_name" {
  description = "DynamoDB orders table name"
  value       = module.dynamodb.table_name
}

output "step_function_arn" {
  description = "Step Functions state machine ARN"
  value       = module.step_functions.state_machine_arn
}

output "order_queue_url" {
  description = "SQS order queue URL"
  value       = module.sqs.order_queue_url
}

output "dlq_url" {
  description = "Dead letter queue URL"
  value       = module.sqs.dlq_url
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  })
}