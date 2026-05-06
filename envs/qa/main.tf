# --- 1. Networking ---
module "networking" {
  source            = "../../modules/networking"
  environment       = "qa"
  region            = "us-east-1"
  vpc_cidr          = "10.0.0.0/16"
  az_a              = "us-east-1a"
  az_b              = "us-east-1b"
  nat_gateway_count = 1
}

# --- 2. Messaging (SQS) ---
module "messaging" {
  source      = "../../modules/messaging"
  environment = "qa"
  bucket_arn  = module.storage.bucket_arn
}

# --- 3. Storage (S3) ---
module "storage" {
  source        = "../../modules/storage"
  environment   = "qa"
  sqs_queue_arn = module.messaging.sqs_arn
}

# --- 4. Observability (Logs) ---
module "observability" {
  source                = "../../modules/observability"
  environment           = "qa"
  tiempo_retencion_logs = 7
}

# --- 5. Compute (Lambdas) ---
module "compute" {
  source              = "../../modules/compute"
  environment         = "qa"
  bucket_id           = module.storage.bucket_id
  bucket_arn          = module.storage.bucket_arn
  sqs_main_queue_arn  = module.messaging.sqs_arn
  private_subnet_ids  = module.networking.private_subnets
  sg_upload_lambda_id = module.networking.lambda_sg_id
  sg_crop_lambda_id   = module.networking.lambda_sg_id
}

# --- 6. API Gateway ---
module "api_gateway" {
  source             = "../../modules/api_gateway"
  environment        = "qa"
  upload_lambda_arn  = module.compute.upload_lambda_arn
  upload_lambda_name = module.compute.upload_lambda_name
  log_group_arn      = module.observability.log_group_api_arn
}