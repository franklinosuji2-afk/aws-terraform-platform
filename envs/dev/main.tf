terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80, < 7.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Bucket name comes from `bootstrap` output; pass it with:
  #   terraform init -backend-config="bucket=<state_bucket>"
  backend "s3" {
    key          = "envs/dev/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

locals {
  name = "${var.project}-dev"
}

module "vpc" {
  source = "../../modules/vpc"

  name               = local.name
  region             = var.region
  cidr_block         = var.vpc_cidr
  az_count           = 2
  enable_nat_gateway = var.enable_nat_gateway
}

# Free-tier friendly public endpoint: Lambda + function URL (no load balancer, no Fargate).
module "web" {
  source = "../../modules/lambda-service"
  count  = var.enable_lambda ? 1 : 0

  name                 = local.name
  environment          = "dev"
  reserved_concurrency = var.lambda_reserved_concurrency
}

# Off by default: the load balancer and Fargate task are the only billable parts of this stack.
module "app" {
  source = "../../modules/ecs-service"
  count  = var.enable_app ? 1 : 0

  name              = local.name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  # Without a NAT gateway, tasks sit in public subnets with a public IP so they
  # can pull the image. Their security group still only accepts traffic from the ALB.
  task_subnet_ids  = var.enable_nat_gateway ? module.vpc.private_subnet_ids : module.vpc.public_subnet_ids
  assign_public_ip = !var.enable_nat_gateway

  container_image      = var.container_image
  desired_count        = var.desired_count
  allowed_ingress_cidr = var.allowed_ingress_cidr
  certificate_arn      = var.certificate_arn
}

# Email alert if the account's monthly cost forecast or actual spend passes the limit.
# The first two budgets per account are free.
resource "aws_budgets_budget" "cost_guard" {
  count = var.budget_email == null ? 0 : 1

  name         = "${local.name}-cost-guard"
  budget_type  = "COST"
  limit_amount = tostring(var.budget_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_email]
  }
}