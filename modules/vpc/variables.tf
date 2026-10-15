variable "name" {
  description = "Name prefix for all VPC resources."
  type        = string
}

variable "region" {
  description = "AWS region, used for the S3 gateway endpoint service name."
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC. Subnets are carved out of it with cidrsubnet()."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets over (2 or 3)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "enable_nat_gateway" {
  description = "Create a single NAT gateway for the private subnets (billed hourly)."
  type        = bool
  default     = false
}