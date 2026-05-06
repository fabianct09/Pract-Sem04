variable "environment" {
  description = "Entorno de despliegue (dev, qa, prod)"
  type        = string
}

variable "region" {
  description = "Región de AWS"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
}

variable "az_a" {
  description = "Availability Zone A"
  type        = string
}

variable "az_b" {
  description = "Availability Zone B"
  type        = string
}

variable "nat_gateway_count" {
  description = "Cantidad de NAT Gateways a desplegar (1 o 2)"
  type        = number
}