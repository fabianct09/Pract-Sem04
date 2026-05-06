variable "environment" {
  type        = string
  description = "Entorno de despliegue"
}

variable "bucket_id" {
  type        = string
  description = "ID del bucket de S3"
}

variable "bucket_arn" {
  type        = string
  description = "ARN del bucket de S3"
}

variable "sqs_main_queue_arn" {
  type        = string
  description = "ARN de la cola SQS"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Lista de IDs de subredes privadas"
}

variable "sg_upload_lambda_id" {
  type        = string
  description = "Security Group para la Lambda de subida"
}

variable "sg_crop_lambda_id" {
  type        = string
  description = "Security Group para la Lambda de recorte"
}