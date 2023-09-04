terraform {
  required_version = ">= v1.5.2"
  required_providers {
    aws = {
      version = "= 5.14.0"
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

locals {
  lb_subnets  = split(",", var.lb_subnet_id_list)
  app_subnets = split(",", var.app_subnet_id_list)
  ecr_tag     = var.stage
}

data "aws_caller_identity" "self" {
}

module "ecr" {
  source = "./modules/ecr"

  aws_account_id   = data.aws_caller_identity.self.account_id
  aws_region       = var.aws_region
  aws_profile      = var.aws_profile
  image_name       = var.image_name
  image_tag        = local.ecr_tag
  local_image_name = var.local_image_name
  local_image_tag  = local.ecr_tag
}


module "alb" {
  source = "./modules/alb"

  app_name = var.app_name
  app_port = var.container_port
  stage    = var.stage
  vpc_id   = var.vpc_id
  subnets  = local.lb_subnets
}


module "ecs_service" {
  source = "./modules/ecs"

  region                = var.aws_region
  app_name              = var.app_name
  stage                 = var.stage
  vpc_id                = var.vpc_id
  subnets               = local.app_subnets
  ecr_image_url         = "${module.ecr.image_url}:${local.ecr_tag}"
  container_name        = var.app_name
  container_port        = var.container_port
  lb_listener_arn       = module.alb.listener_arn
  health_check_port     = var.container_port
  health_check_path     = "/healthz"
  log_retention_in_days = 7
  desired_count         = var.container_count
}


output "app_url" {
  value = "http://${module.alb.dns_name}"
}
