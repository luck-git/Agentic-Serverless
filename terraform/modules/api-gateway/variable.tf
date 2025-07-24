variable "project_name" {
  description = "Name of the project"
  type        = string
}

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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}