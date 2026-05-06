output "api_url" {
  description = "URL del API Gateway para subir imagenes"
  value       = module.api_gateway.base_url
}

output "bucket_name" {
  description = "Nombre del bucket de imagenes creado"
  value       = module.storage.bucket_id
}