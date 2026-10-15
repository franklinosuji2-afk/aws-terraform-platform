output "web_url" {
  description = "Public HTTPS URL of the Lambda demo, or null while enable_lambda is false."
  value       = var.enable_lambda ? module.web[0].function_url : null
}

output "app_url" {
  description = "URL of the demo service, or null while enable_app is false."
  value       = var.enable_app ? "http://${module.app[0].alb_dns_name}" : null
}

output "cluster_name" {
  description = "ECS cluster name, or null while enable_app is false."
  value       = var.enable_app ? module.app[0].cluster_name : null
}

output "log_group_name" {
  description = "CloudWatch log group for the service, or null while enable_app is false."
  value       = var.enable_app ? module.app[0].log_group_name : null
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}