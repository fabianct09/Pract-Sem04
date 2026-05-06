output "main_queue_url" {
  description = "URL de la SQS Main Queue"
  value       = aws_sqs_queue.main.id
}

output "main_queue_arn" {
  description = "ARN de la SQS Main Queue"
  value       = aws_sqs_queue.main.arn
}

output "dlq_arn" {
  description = "ARN de la SQS DLQ"
  value       = aws_sqs_queue.dlq.arn
}