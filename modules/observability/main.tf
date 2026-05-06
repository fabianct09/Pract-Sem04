# --- Permisos para que API Gateway escriba logs ---
resource "aws_iam_role" "rol_logs_gateway" {
  name = "upao-apigw-logging-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "adjuntar_politica_logs" {
  role       = aws_iam_role.rol_logs_gateway.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "config_cuenta_logs" {
  cloudwatch_role_arn = aws_iam_role.rol_logs_gateway.arn
}

# --- Grupos de Logs Personalizados ---
# IMPORTANTE: El nombre debe coincidir con el de tus Lambdas de la Etapa 5
resource "aws_cloudwatch_log_group" "logs_lambda_subida" {
  name              = "/aws/lambda/upao-upload-service-${var.environment}"
  retention_in_days = var.tiempo_retencion_logs
}

resource "aws_cloudwatch_log_group" "logs_lambda_recorte" {
  name              = "/aws/lambda/upao-crop-service-${var.environment}"
  retention_in_days = var.tiempo_retencion_logs
}

resource "aws_cloudwatch_log_group" "logs_api_gateway" {
  name              = "/aws/apigateway/upao-main-api-${var.environment}"
  retention_in_days = var.tiempo_retencion_logs
}