variable "name" {
  description = "Function name; also used as the IAM role and log group prefix."
  type        = string
}

variable "environment" {
  description = "Environment label exposed to the function."
  type        = string
  default     = "dev"
}

variable "memory_size" {
  description = "Memory in MB."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 14
}

variable "reserved_concurrency" {
  description = "Cap on concurrent executions. Null means no cap."
  type        = number
  default     = null
}