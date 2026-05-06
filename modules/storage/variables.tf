variable "environment" {
  description = "Entorno (qa, dev, prod)"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN de la cola SQS"
  type        = string
}