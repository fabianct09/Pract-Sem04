output "private_subnets" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

# Opción A: si el módulo compute solo usa la Lambda de upload
output "lambda_sg_id" {
  value = aws_security_group.upload_lambda.id
}

# Opción B: si necesitas ambos SGs por separado
output "upload_lambda_sg_id" {
  value = aws_security_group.upload_lambda.id
}

output "crop_lambda_sg_id" {
  value = aws_security_group.crop_lambda.id
}