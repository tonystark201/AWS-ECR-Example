
output "endpoint_url" {
  description = "alb endpoint to visit"
  value       = aws_alb.alb-lb.dns_name
}

output "ecr_repo_url" {
  description = "ecr repo url"
  value       = aws_ecr_repository.demo-repository.repository_url
}

