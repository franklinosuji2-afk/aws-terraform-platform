variable "region" {
  description = "AWS region for the state bucket and IAM resources' home region."
  type        = string
  default     = "eu-central-1"
}

variable "project" {
  description = "Short name used as a prefix for all resources."
  type        = string
  default     = "tfplatform"
}

variable "github_org" {
  description = "GitHub user or organisation that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without the owner)."
  type        = string
}

variable "environment_name" {
  description = "GitHub environment whose jobs may assume the apply role."
  type        = string
  default     = "dev"
}

variable "state_bucket_name" {
  description = "Override for the state bucket name. Defaults to <project>-tfstate-<account>-<region>."
  type        = string
  default     = null
}