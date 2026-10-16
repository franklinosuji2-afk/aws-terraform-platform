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

variable "github_org_id" {
  description = "Numeric GitHub owner ID. Newer repositories put it into the OIDC subject (repo:OWNER@ID/REPO@ID:...). Set together with github_repo_id; leave both null for the classic repo:OWNER/REPO format."
  type        = string
  default     = null
}

variable "github_repo_id" {
  description = "Numeric GitHub repository ID, see github_org_id."
  type        = string
  default     = null

  validation {
    condition     = (var.github_repo_id == null) == (var.github_org_id == null)
    error_message = "Set github_org_id and github_repo_id together, or neither."
  }
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