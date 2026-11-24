# ==============================================================================
# Application Load Balancer (ALB) y Target Group
# ==============================================================================

# Application Load Balancer Multi-AZ (desplegado en las 3 subredes públicas)
resource "aws_lb" "main" {
  name               = "alb-${var.project_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1b.id,
    aws_subnet.public_1c.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "alb-${var.project_name}"
  }
}

# Target Group para registrar instancias NGINX
resource "aws_lb_target_group" "main" {
  name        = "tg-${var.project_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = {
    Name = "tg-${var.project_name}"
  }
}

# Listener HTTP en el puerto 80 que redirige al Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
