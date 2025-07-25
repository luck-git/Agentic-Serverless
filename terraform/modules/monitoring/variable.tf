variable "prefix" {
  description = "Resource name prefix (usually project-environment)"
  type        = string
}

variable "dlq_arn" {
  description = "ARN of the Dead Letter Queue to monitor"
  type        = string
}

variable "step_function_arn" {
  description = "ARN of the Step Function to monitor"
  type        = string
}

variable "api_gateway_id" {
  description = "ID of the API Gateway to monitor (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}