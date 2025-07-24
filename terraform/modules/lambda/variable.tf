variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "orders_table" {
  description = "DynamoDB orders table name"
  type        = string
}

variable "orders_table_arn" {
  description = "DynamoDB orders table ARN"
  type        = string
}

variable "order_queue_url" {
  description = "SQS order queue URL"
  type        = string
}

variable "order_queue_arn" {
  description = "SQS order queue ARN"
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

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}