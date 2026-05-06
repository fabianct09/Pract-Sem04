variable "environment" {
  description = "Entorno de despliegue (dev, qa, prod)"
  type        = string
}

variable "bucket_arn" {
  description = "ARN del bucket S3 para la política de permisos de SQS"
  type        = string
}