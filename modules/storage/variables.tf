variable "environment" {
  description = "Entorno de despliegue (dev, qa, prod)"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN de la cola SQS principal para enviar notificaciones de S3"
  type        = string
}