output "base_url" {
  description = "URL de la API"
  value       = "${aws_api_gateway_stage.stage.invoke_url}/upload"
}