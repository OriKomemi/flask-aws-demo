terraform {
  backend "s3" {
    bucket         = "flask-aws-demo-terraform-state"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "flask-aws-demo-terraform-locks"
    encrypt        = true
  }
}
