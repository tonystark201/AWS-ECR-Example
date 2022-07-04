###################
# Default VPC and Subnets
###################
# data "aws_vpc" "default" {
#   default = true
# }

# data "aws_subnet_ids" "all" {
#   vpc_id = data.aws_vpc.default.id
# }

# data "aws_security_group" "default" {
#   vpc_id = data.aws_vpc.default.id
# }

###################
# ECR
###################
resource "aws_ecr_repository" "demo-repository" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_repository_policy" "demo-repo-policy" {
  repository = aws_ecr_repository.demo-repository.name
  policy     = jsonencode(
    {
      "Version": "2008-10-17",
      "Statement": [
        {
          "Sid": "adds full ecr access to the demo repository",
          "Effect": "Allow",
          "Principal": "*",
          "Action": [
            "ecr:BatchCheckLayerAvailability",
            "ecr:BatchGetImage",
            "ecr:CompleteLayerUpload",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetLifecyclePolicy",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:UploadLayerPart"
          ]
        }
      ]
    }
  )
}

###################
# Build and Push
###################
resource "null_resource" "push" {

  provisioner "local-exec" {
#    command     = <<EOT
#      docker build -t demo:latest ./src &
#      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.demo-repository.repository_url} &
#      docker tag demo:latest ${aws_ecr_repository.demo-repository.repository_url}:v2 &
#      docker push ${aws_ecr_repository.demo-repository.repository_url}:v2
#    EOT
    command = join("",[
      " docker build -t demo:${var.image_tag} ./src & ",
      " aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.demo-repository.repository_url} &",
      " docker tag demo:${var.image_tag} ${aws_ecr_repository.demo-repository.repository_url}:${var.image_tag} & ",
      " docker push ${aws_ecr_repository.demo-repository.repository_url}:${var.image_tag}"
    ])
  }
}

###################
# ALB
###################
resource "aws_alb" "alb-lb" {
  name           = "${var.project_name}-alb"
  load_balancer_type = "application"
  subnets        = module.vpc.public_subnets
  security_groups = [module.alb_sg.security_group_id]
}

resource "aws_alb_target_group" "alb-tg" {
  name        = "${var.project_name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    protocol            = "HTTP"
    matcher             = "200"
    path                = var.health_check_path
    interval            = 10
  }
}

resource "aws_alb_listener" "alb-lt" {
  load_balancer_arn = aws_alb.alb-lb.id
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb-tg.arn
  }
}


###################
# ECS task execution role
###################
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-iam-role"
  assume_role_policy =  jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": "ecs-tasks.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

###################
# ECS
###################
resource "aws_ecs_cluster" "demo-ecs-cluster" {
  name = "ecs-cluster-for-demo"
}

resource "aws_ecs_service" "demo-ecs-service-two" {
  name            = "${var.project_name}-app"
  cluster         = aws_ecs_cluster.demo-ecs-cluster.id
  task_definition = aws_ecs_task_definition.demo-ecs-task-definition.arn
  launch_type     = "FARGATE"
  desired_count = 2

  network_configuration {
    security_groups  = [module.ecs_sg.security_group_id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.alb-tg.arn
    container_name   = "${var.project_name}-app"
    container_port   = var.app_port
  }

  depends_on = [
    aws_alb_listener.alb-lt
  ]
}

resource "aws_ecs_task_definition" "demo-ecs-task-definition" {
  family                   = "${var.project_name}-td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = "1024"
  cpu                      = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode(
    [{
      "name": "${var.project_name}-app",
      "image": "${aws_ecr_repository.demo-repository.repository_url}:${var.image_tag}",
      "memory": 1024,
      "cpu": 512,
      "essential": true,
      "command": ["python","/home/service/main.py"],
      "portMappings": [
        {
          "containerPort": var.app_port,
          "hostPort": var.app_port
        }
      ]
    }]
  )
  depends_on = [
    null_resource.push
  ]
}