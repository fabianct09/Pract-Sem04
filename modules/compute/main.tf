# --- Empaquetado automático de funciones ---
data "archive_file" "zip_subida" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/upload"
  output_path = "${path.root}/lambda/upload_dist.zip"
}

data "archive_file" "zip_recorte" {
  type        = "zip"
  source_dir  = "${path.root}/lambda/crop"
  output_path = "${path.root}/lambda/crop_dist.zip"
}

# --- Rol de ejecución IAM ---
resource "aws_iam_role" "rol_servicios_ia" {
  name = "upao-ia-exec-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "permisos_red" {
  role       = aws_iam_role.rol_servicios_ia.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# --- Configuración de Lambdas ---
resource "aws_lambda_function" "lambda_upload" {
  function_name    = "upao-upload-service-${var.environment}"
  role             = aws_iam_role.rol_servicios_ia.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.zip_subida.output_path
  source_code_hash = data.archive_file.zip_subida.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_upload_lambda_id]
  }
}

resource "aws_lambda_function" "lambda_crop" {
  function_name    = "upao-crop-service-${var.environment}"
  role             = aws_iam_role.rol_servicios_ia.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 60
  filename         = data.archive_file.zip_recorte.output_path
  source_code_hash = data.archive_file.zip_recorte.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_crop_lambda_id]
  }
}

# --- Trigger SQS ---
resource "aws_lambda_event_source_mapping" "union_sqs_lambda" {
  event_source_arn = var.sqs_main_queue_arn
  function_name    = aws_lambda_function.lambda_crop.arn
  batch_size       = 5
}