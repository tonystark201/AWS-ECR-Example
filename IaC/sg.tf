###################
# Security Gateway
###################

module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name        = "${var.project_name}-alb-sg"
  description = "alb sg"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = var.app_port
      to_port     = var.app_port
      protocol    = "tcp"
      description = "${var.project_name}-app-port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "${var.project_name}-app-port"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

   egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "${var.project_name}-app-port"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "ecs_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name        = "${var.project_name}-ecs-sg"
  description = "ecs sg"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id =[
    {
      from_port   = var.app_port
      to_port     = var.app_port
      protocol    = "tcp"
      description = "${var.project_name}-app-port"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "${var.project_name}-app-port"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

