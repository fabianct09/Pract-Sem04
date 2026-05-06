output "upload_lambda_name" {
  value = aws_lambda_function.upload_service.function_name
}

output "upload_lambda_arn" {
  value = aws_lambda_function.upload_service.arn
}