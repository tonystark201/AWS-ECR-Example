variable "aws_region" {
  default     = "us-east-1"
  description = "aws region where our resources going to create choose"
}

variable "aws_access_key" {
  type = string
  description = "aws_access_key"
}

variable "aws_secret_key" {
  type = string
  description = "aws_secret_key"
}

variable "project_name" {
  type = string
  description = "project name"
  default = "ecs-demo"
}

variable "image_tag" {
  type = string
  description = "image tag"
}

variable "health_check_path" {
  type = string
  description = "health_check_path "
  default = "/health-check"
}

variable "app_port" {
  type = number
  description = "app port "
  default = 8080
}