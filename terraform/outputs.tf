# ==============================================================================
# Outputs (Valores de Salida)
# ==============================================================================

output "alb_dns_name" {
  description = "URL pública del Application Load Balancer para acceder a la aplicación"
  value       = "http://${aws_lb.main.dns_name}"
}

output "vpc_id" {
  description = "ID de la VPC principal"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "IDs de las 3 subredes públicas Multi-AZ"
  value = {
    "us-east-1a" = aws_subnet.public_1a.id,
    "us-east-1b" = aws_subnet.public_1b.id,
    "us-east-1c" = aws_subnet.public_1c.id
  }
}

output "target_group_arn" {
  description = "ARN del Target Group"
  value       = aws_lb_target_group.main.arn
}

output "autoscaling_group_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "launch_template_id" {
  description = "ID de la plantilla de lanzamiento"
  value       = aws_launch_template.main.id
}
