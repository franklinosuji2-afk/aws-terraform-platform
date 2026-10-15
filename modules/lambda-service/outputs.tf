output "function_url" {
  description = "Public HTTPS URL of the function."
  value       = aws_lambda_function_url.this.function_url
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}