locals {
  region       = var.region
  project_name = var.project_name
  environment  = var.environment
}

# create vpc module
module "vpc" {
  source                       = "git@github.com:shittus/terraform-modules.git//vpc"
  region                       = local.region
  project_name                 = local.project_name
  environment                  = local.environment
  vpc_cidr                     = var.vpc_cidr
  public_subnet_az1_cidr       = var.public_subnet_az1_cidr
  public_subnet_az2_cidr       = var.public_subnet_az2_cidr
  private_app_subnet_az1_cidr  = var.private_app_subnet_az1_cidr
  private_app_subnet_az2_cidr  = var.private_app_subnet_az2_cidr
  private_data_subnet_az1_cidr = var.private_data_subnet_az1_cidr
  private_data_subnet_az2_cidr = var.private_data_subnet_az2_cidr


}

#NAT Gateway module

module "nat_gatway" {
  source                     = "git@github.com:shittus/terraform-modules.git//nat-gatway"
  project_name               = local.project_name
  environment                = local.environment
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  internet_gateway           = module.vpc.internet_gateway
  public_subnet_az2_id       = module.vpc.public_subnet_az2_id
  vpc_id                     = module.vpc.vpc_id
  private_data_subnet_az1    = module.vpc.private_data_subnet_az1_id
  availability_zone_1        = module.vpc.availability_zone_1
  private_app_subnet_az1_id  = module.vpc.private_app_subnet_az1_id
  private_data_subnet_az1_id = module.vpc.private_data_subnet_az1_id
  private_app_subnet_az2_id  = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az2_id = module.vpc.private_data_subnet_az2_id



}

# create security group
module "security-group" {
  source       = "git@github.com:shittus/terraform-modules.git//security-group"
  project_name = local.project_name
  environment  = local.environment
  vpc_id       = module.vpc.vpc_id
  ssh_ip       = var.ssh_ip
}

# RDS Instance
module "rds" {
  source                       = "git@github.com:shittus/terraform-modules.git//rds"
  project_name                 = local.project_name
  environment                  = local.environment
  private_data_subnet_az1_id   = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id   = module.vpc.private_data_subnet_az2_id
  database_snapshot_identifier = var.database_snapshot_identifier
  database_instance_class      = var.database_instance_class
  availability_zone_1          = module.vpc.availability_zone_1
  database_instance_identifier = var.database_instance_identifier
  multi_az_deployment          = var.multi_az_deployment
  database_security_group_id   = module.security-group.database_security_group_id

}

# request SSL certificate

module "ssl_certificate" {
  source            = "git@github.com:shittus/terraform-modules.git//acm"
  domain_name       = var.domain_name
  alternative_names = var.alternative_names
}

# Application Load balancer
  module "alb" {
    source = "https://github.com/shittus/terraform-modules.git//alb"
    project_name = var.project_name
    environment = var.environment
    alb_security_group_id = module.security-group.alb_security_group_id
    public_subnet_az1_id = module.vpc.public_subnet_az1_id
    public_subnet_az2_id =module.vpc.ublic_subnet_az2_id
    target_type = var.target_type
    vpc_id = module.vpc.vpc_id
    validated_certificate_arn = module.ssl_certificate.validated_certificate_arn
    
  }

