locals {
  region = var.region
  project_name = var.project_name
  environment = var.environment
}

# create vpc module
module "vpc" {
    source = "git@github.com:shittus/terraform-modules.git//vpc"

    
  
}