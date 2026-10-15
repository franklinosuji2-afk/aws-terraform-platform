variable "name" {
  description = "Name used for the cluster, service, load balancer and roles."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,24}$", var.name))
    error_message = "name must be 1-24 characters: lowercase letters, digits and hyphens (ALB name limit)."
  }
}

variable "vpc_id" {
  description = "VPC to deploy into."
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnets for the load balancer."
  type        = list(string)
}

variable "task_subnet_ids" {
  description = "Subnets for the Fargate tasks."
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Give tasks a public IP so they can pull images without a NAT gateway."
  type        = bool
  default     = false
}

variable "container_image" {
  description = "Container image to run."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path the load balancer uses for health checks."
  type        = string
  default     = "/"
}

variable "cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of tasks to run."
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 14
}

variable "allowed_ingress_cidr" {
  description = "CIDR allowed to reach the load balancer. Restrict this to your own IP while testing."
  type        = string
  default     = "0.0.0.0/0"
}

variable "certificate_arn" {
  description = "ACM certificate ARN. When set, HTTP redirects to HTTPS."
  type        = string
  default     = null
}