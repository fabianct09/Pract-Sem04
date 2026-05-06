variable "environment" {
  type        = string
  description = "Entorno (dev, qa, prod)"
}

variable "upload_lambda_arn" {
  type        = string
  description = "ARN de la Lambda de subida"
}

variable "upload_lambda_name" {
  type        = string
  description = "Nombre de la Lambda de subida"
}

variable "log_group_arn" {
  type        = string
  description = "ARN del Log Group creado en la etapa 6"
}