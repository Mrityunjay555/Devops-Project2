terraform {
  backend "s3" {
    bucket         = "terraform-state-1762186276-xanderbilla"
    key            = "puppet-infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
