variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "validator_lambda_arn" {
  description = "ARN of the order validator Lambda function"
  type        = string
}

variable "fulfillment_lambda_arn" {
  description = "ARN of the order fulfillment Lambda function"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}