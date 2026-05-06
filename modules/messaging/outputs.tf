output "sqs_url" {
  value       = aws_sqs_queue.main_event_queue.id
  description = "URL de la cola principal"
}

output "sqs_arn" {
  value       = aws_sqs_queue.main_event_queue.arn
  description = "ARN de la cola principal"
}