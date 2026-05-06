# --- IAM Role para Upload Lambda ---
resource "aws_iam_role" "upload_lambda_role" {
  name = "upao-upload-lambda-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "upload_basic" {
  role       = aws_iam_role.upload_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "upload_vpc" {
  role       = aws_iam_role.upload_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "upload_s3" {
  name = "upload-s3-policy-${var.environment}"
  role = aws_iam_role.upload_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:PutObject"
      Resource = "${var.bucket_arn}/uploads/*"
    }]
  })
}

# --- IAM Role para Crop Lambda ---
resource "aws_iam_role" "crop_lambda_role" {
  name = "upao-crop-lambda-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "crop_basic" {
  role       = aws_iam_role.crop_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "crop_vpc" {
  role       = aws_iam_role.crop_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "crop_s3_sqs" {
  name = "crop-s3-sqs-policy-${var.environment}"
  role = aws_iam_role.crop_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${var.bucket_arn}/uploads/*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${var.bucket_arn}/processed/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = var.sqs_main_queue_arn
      }
    ]
  })
}

# --- Lambda Upload ---
resource "aws_lambda_function" "upload_service" {
  filename      = "${path.module}/../../lambda/upload/upload.zip"
  function_name = "upao-upload-service-${var.environment}"
  role          = aws_iam_role.upload_lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  memory_size   = 256
  timeout       = 30

  environment {
    variables = {
      S3_BUCKET     = var.bucket_id
      UPLOAD_PREFIX = "uploads/"
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_upload_lambda_id]
  }
}

# --- Lambda Crop ---
resource "aws_lambda_function" "crop_service" {
  filename      = "${path.module}/../../lambda/crop/crop.zip"
  function_name = "upao-crop-service-${var.environment}"
  role          = aws_iam_role.crop_lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  memory_size   = 512
  timeout       = 60

  environment {
    variables = {
      S3_BUCKET        = var.bucket_id
      PROCESSED_PREFIX = "processed/"
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_crop_lambda_id]
  }
}

# --- Event Source Mapping (SQS → Crop Lambda) ---
resource "aws_lambda_event_source_mapping" "sqs_to_crop" {
  event_source_arn        = var.sqs_main_queue_arn
  function_name           = aws_lambda_function.crop_service.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]
}