variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Environment (dev/stage/prod)"
}
variable "github_owner"   { type = string }
variable "github_repo"    { type = string }
variable "github_token"   { type = string }
variable "github_branch"  { type = string }

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags for all resources"
}