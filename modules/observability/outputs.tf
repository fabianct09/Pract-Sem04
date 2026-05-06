output "log_group_api_arn" {
  value       = aws_cloudwatch_log_group.logs_api_gateway.arn
  description = "ARN para vincular con el Stage de API Gateway"
}