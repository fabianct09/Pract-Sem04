# 1. Generar sufijo aleatorio para evitar nombres duplicados en AWS
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 2. Definición del Bucket S3 (Solo uno)
resource "aws_s3_bucket" "images" {
  # Usamos el nombre que definimos con el sufijo aleatorio
  bucket = "upao-processor-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "upao-processor-${var.environment}-images"
    Environment = var.environment
  }
}

# 3. Bloqueo de acceso público (Seguridad)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. Encriptación AES256
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 5. Versionado
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.images.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# 6. Ciclo de vida (Limpieza automática de fotos viejas)
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "expire-uploads"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    expiration {
      days = 30
    }
  }

  rule {
    id     = "expire-processed"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    expiration {
      days = 90
    }
  }
}

# 7. Notificación de eventos a SQS
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.images.id

  queue {
    queue_arn     = var.sqs_queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }
}