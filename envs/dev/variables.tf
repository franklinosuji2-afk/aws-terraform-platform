variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-central-1"
}

variable "project" {
  description = "Resource name prefix. Must match the project used in bootstrap (IAM permissions are scoped to it)."
  type        = string
  default     = "tfplatform"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway and run tasks in private subnets (billed hourly)."
  type        = bool
  default     = false
}

variable "container_image" {
  description = "Container image for the demo service."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
}

variable "desired_count" {
  description = "Number of Fargate tasks."
  type        = number
  default     = 1
}

variable "allowed_ingress_cidr" {
  description = "CIDR allowed to reach the load balancer. Set this to your own IP/32 while testing."
  type        = string
  default     = "0.0.0.0/0"
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN to enable HTTPS."
  type        = string
  default     = null
}

variable "enable_app" {
  description = "Create the ALB + Fargate service. Off by default because these are the billable resources."
  type        = bool
  default     = false
}

variable "budget_email" {
  description = "Email address for the cost alert. Leave null to skip creating the budget."
  type        = string
  default     = null
}

variable "budget_limit_usd" {
  description = "Monthly cost limit (USD) that triggers the alert."
  type        = number
  default     = 1
}

variable "enable_lambda" {
  description = "Create the Lambda function and its public URL (inside the AWS Lambda free tier at demo traffic)."
  type        = bool
  default     = true
}

variable "lambda_reserved_concurrency" {
  description = "Optional cap on parallel Lambda executions. Leave null on new accounts (AWS keeps 10 unreserved)."
  type        = number
  default     = null
}