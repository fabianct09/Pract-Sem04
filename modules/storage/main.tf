# Generar un sufijo aleatorio para evitar colisiones de nombres globales en S3
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# --- Bucket S3 ---
resource "aws_s3_bucket" "images" {
  bucket = "image-processor-${var.environment}-images-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "image-processor-${var.environment}-images"
    Environment = var.environment
  }
}

# Bloqueo de acceso público total habilitado
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encriptación del lado del servidor (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versionado habilitado
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.images.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Ciclo de vida para los prefijos uploads/ y processed/
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

# Notificación de eventos a SQS
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.images.id

  queue {
    queue_arn     = var.sqs_queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }
}