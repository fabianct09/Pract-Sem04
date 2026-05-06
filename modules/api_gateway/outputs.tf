# modules/api_gateway/outputs.tf
output "base_url" {
  value = "${aws_api_gateway_stage.stage.invoke_url}/upload"
}