variable "region" {}
variable "project_name" {}
variable "environment" {}

# VPC
variable "vpc_cidr" {}
variable "public_subnet_az1_cidr" {}
variable "public_subnet_az2_cidr" {}
variable "private_app_subnet_az1_cidr" {}
variable "private_app_subnet_az2_cidr" {}
variable "private_data_subnet_az1_cidr" {}
variable "private_data_subnet_az2_cidr" {}

variable "ssh_ip" {}

# Database vaiable
variable "database_instance_class" {}
variable "database_snapshot_identifier" {}
variable "multi_az_deployment" {}
variable "database_instance_identifier" {}

# ACM variables
variable "domain_name" {}
variable "alternative_names" {}

#alb variables
variable "target_type" {}

# s3 variables
variable "env_file_bucket_name" {}
variable "env_file_name" {}