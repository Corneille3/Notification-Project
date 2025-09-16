output "alb_dns" {
  value       = aws_lb.internal.dns_name
  description = "Internal ALB DNS"
}

/*output "api_invoke_url" {
  value       = aws_apigatewayv2_stage.prod.invoke_url
  description = "Public HTTPS URL for the HTTP API (fronts the internal ALB via VPC Link)"
}*/

# For $default, use the API endpoint (no /stage suffix)
output "api_invoke_url" {
  value       = aws_apigatewayv2_api.internal.api_endpoint
  description = "Public HTTPS base URL for the HTTP API"
}


