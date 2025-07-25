variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Environment (dev/stage/prod)"
}

variable "github_owner" {
  type        = string
  description = "GitHub repository owner"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}

variable "github_branch" {
  type        = string
  default     = "main"
  description = "GitHub branch to use"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub OAuth token"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags for all resources"
}