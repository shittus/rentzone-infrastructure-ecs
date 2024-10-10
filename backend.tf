terraform {
  backend "s3" {
    bucket = "terraformremotestate-1"
    key = "terraform-module/rentzone/terraformt.tfstate"
    region = "us-east-1"
    profile = "terraform-user"
    dynamodb_table = "terraform-state-lock"
    
    
  }
}