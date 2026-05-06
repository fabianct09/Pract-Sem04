# --- Definición de la API REST ---
resource "aws_api_gateway_rest_api" "api_procesamiento" {
  name        = "upao-image-api-${var.environment}"
  description = "Endpoint para el procesamiento distribuido de imagenes"
}

# --- Recurso /upload ---
resource "aws_api_gateway_resource" "ruta_upload" {
  rest_api_id = aws_api_gateway_rest_api.api_procesamiento.id
  parent_id   = aws_api_gateway_rest_api.api_procesamiento.root_resource_id
  path_part   = "upload"
}

# --- Método POST ---
resource "aws_api_gateway_method" "metodo_post" {
  rest_api_id   = aws_api_gateway_rest_api.api_procesamiento.id
  resource_id   = aws_api_gateway_resource.ruta_upload.id
  http_method   = "POST"
  authorization = "NONE"
}

# --- Integración Proxy con Lambda ---
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_procesamiento.id
  resource_id             = aws_api_gateway_resource.ruta_upload.id
  http_method             = aws_api_gateway_method.metodo_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.upload_lambda_arn}/invocations"
}

# --- Permiso para que API Gateway invoque la Lambda ---
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.upload_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_procesamiento.execution_arn}/*/*"
}

# --- Despliegue (Stage) ---
resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.api_procesamiento.id
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_procesamiento.id
  stage_name    = var.environment

  access_log_settings {
    destination_arn = var.log_group_arn
    format          = jsonencode({
      requestId = "$context.requestId",
      ip        = "$context.identity.sourceIp",
      status    = "$context.status",
      method    = "$context.httpMethod",
      path      = "$context.resourcePath"
    })
  }
}

data "aws_region" "current" {}