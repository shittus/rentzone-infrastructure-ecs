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

  depends_on = [
    module.vpc # Ensure VPC is created before NAT Gateway
  ]



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

  depends_on = [
    module.vpc,           # Wait for VPC creation
    module.security-group # Wait for security group creation
  ]

}

# request SSL certificate

module "ssl_certificate" {
  source            = "git@github.com:shittus/terraform-modules.git//acm"
  domain_name       = var.domain_name
  alternative_names = var.alternative_names
}

# Application Load balancer
module "alb" {
  source                    = "git@github.com:shittus/terraform-modules.git//alb"
  project_name              = var.project_name
  environment               = var.environment
  alb_security_group_id     = module.security-group.alb_security_group_id
  public_subnet_az1_id      = module.vpc.public_subnet_az1_id
  public_subnet_az2_id      = module.vpc.public_subnet_az2_id
  target_type               = var.target_type
  vpc_id                    = module.vpc.vpc_id
  validated_certificate_arn = module.ssl_certificate.validated_certificate_arn

  depends_on = [
    module.ssl_certificate # ALB must wait for SSL certificate validation
  ]

}


# create s3 bucket
module "s3" {
  source               = "git@github.com:shittus/terraform-modules.git//s3"
  project_name         = local.project_name
  env_file_bucket_name = var.env_file_bucket_name
  env_file_name        = var.env_file_name

}

# create ecs iam role execution
module "ecs-task-execution-role" {
  source               = "git@github.com:shittus/terraform-modules.git//iam-role"
  project_name         = local.project_name
  env_file_bucket_name = module.s3.env_file_bucket_name
  environment          = local.environment


}

# create ECS task definition and service
module "ecs" {
  source                       = "git@github.com:shittus/terraform-modules.git//ecs"
  project_name                 = local.project_name
  environment                  = local.environment
  ecs_task_execution_role_arn  = module.ecs-task-execution-role.ecs_task_execution_role_arn
  architecture                 = var.architecture
  container_image              = var.container_image
  env_file_name                = module.s3.env_file_name
  env_file_bucket_name         = module.s3.env_file_name
  region                       = var.region
  private_app_subnet_az2_id    = module.vpc.private_app_subnet_az2_id
  private_app_subnet_az1_id    = module.vpc.private_app_subnet_az2_id
  app_server_security_group_id = module.security-group.app_server_security_group_id
  alb_target_group_arn         = module.alb.alb_target_group_arn


  depends_on = [
    module.s3,                      # Wait for S3 bucket creation
    module.ecs-task-execution-role, # Wait for IAM role creation
    module.alb                      # Wait for ALB and SSL certificate
  ]
}
