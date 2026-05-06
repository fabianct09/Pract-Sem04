variable "environment" { type = string }
variable "bucket_id" { type = string }
variable "bucket_arn" { type = string }
variable "sqs_main_queue_arn" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "sg_upload_lambda_id" { type = string }
variable "sg_crop_lambda_id" { type = string }
variable "lambda_upload_memory" { type = number; default = 256 }
variable "lambda_crop_memory" { type = number; default = 512 }