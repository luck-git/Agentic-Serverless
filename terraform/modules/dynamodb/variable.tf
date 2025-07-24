variable "orders_table_name" {
  type        = string
  description = "Name of the DynamoDB orders table"
  default     = null  # Makes it optional
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name for resource naming"
}

variable "enable_point_in_time_recovery" {
  type        = bool
  default     = true
  description = "Enable point-in-time recovery"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Resource tags"
}