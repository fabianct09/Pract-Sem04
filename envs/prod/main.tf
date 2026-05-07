terraform {
  backend "s3" {
    bucket         = "tf-state-image-processor"
    key            = "envs/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-lock-image-processor"
    encrypt        = true
  }
}

module "networking" {
  source            = "../../modules/networking"
  environment       = "prod"
  region            = "us-east-1"
  vpc_cidr          = "10.0.0.0/16"
  az_a              = "us-east-1a"
  az_b              = "us-east-1b"
  nat_gateway_count = 2
}

module "messaging" {
  source      = "../../modules/messaging"
  environment = "prod"
  bucket_arn  = module.storage.bucket_arn
}

module "storage" {
  source        = "../../modules/storage"
  environment   = "prod"
  sqs_queue_arn = module.messaging.sqs_arn
}

module "observability" {
  source                = "../../modules/observability"
  environment           = "prod"
  tiempo_retencion_logs = 7
}

module "compute" {
  source              = "../../modules/compute"
  environment         = "prod"
  bucket_id           = module.storage.bucket_id
  bucket_arn          = module.storage.bucket_arn
  sqs_main_queue_arn  = module.messaging.sqs_arn
  private_subnet_ids  = module.networking.private_subnets
  sg_upload_lambda_id = module.networking.lambda_sg_id
  sg_crop_lambda_id   = module.networking.lambda_sg_id
}

module "api_gateway" {
  source             = "../../modules/api_gateway"
  environment        = "prod"
  upload_lambda_arn  = module.compute.upload_lambda_arn
  upload_lambda_name = module.compute.upload_lambda_name
  log_group_arn      = module.observability.log_group_api_arn
}