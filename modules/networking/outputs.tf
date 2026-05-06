output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "sg_upload_lambda_id" {
  description = "ID del Security Group para Upload Lambda"
  value       = aws_security_group.upload_lambda.id
}

output "sg_crop_lambda_id" {
  description = "ID del Security Group para Crop Lambda"
  value       = aws_security_group.crop_lambda.id
}

output "vpce_sqs_id" {
  description = "ID del VPC Endpoint de SQS"
  value       = aws_vpc_endpoint.sqs.id
}