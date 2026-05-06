variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
}

variable "tiempo_retencion_logs" {
  description = "Dias que se guardaran los logs"
  type        = number
  default     = 7 # Usamos 7 por defecto para ahorrar costos en DEV
}