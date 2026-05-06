# --- DLQ ---
resource "aws_sqs_queue" "dlq" {
  name                      = "upao-image-dlq-${var.environment}"
  message_retention_seconds = 1209600
}

# --- Cola Principal ---
resource "aws_sqs_queue" "main_event_queue" {
  name                       = "upao-main-queue-${var.environment}"
  visibility_timeout_seconds = 360
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# --- Política para que S3 pueda enviar mensajes ---
resource "aws_sqs_queue_policy" "main_queue_policy" {
  queue_url = aws_sqs_queue.main_event_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.main_event_queue.arn
      Condition = {
        ArnLike = {
          "aws:SourceArn" = var.bucket_arn
        }
      }
    }]
  })
}

# --- Alarma DLQ ---
resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "upao-dlq-alarm-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Mensajes en la DLQ"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}