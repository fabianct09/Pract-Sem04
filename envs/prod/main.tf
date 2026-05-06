terraform {
  backend "s3" {
    bucket         = "tf-state-image-processor"
    key            = "envs/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-lock-image-processor"
    encrypt        = true
  }
}