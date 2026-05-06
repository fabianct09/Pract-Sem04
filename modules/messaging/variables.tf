variable "environment" {
  description = "Entorno de despliegue (ej: qa, dev, prod)"
  type        = string
}

variable "bucket_arn" {
  description = "ARN del bucket de S3 para configurar las políticas de acceso de la cola"
  type        = string
}