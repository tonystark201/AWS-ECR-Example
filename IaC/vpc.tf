###################
# VPC and Subnets
###################
data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name                 = "${var.project_name}-vpc"
  cidr                 = "172.10.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.10.1.0/24", "172.10.2.0/24", "172.10.3.0/24"]
  public_subnets       = ["172.10.4.0/24", "172.10.5.0/24", "172.10.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}