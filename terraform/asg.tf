# ==============================================================================
# Auto Scaling Group (ASG), Políticas de Escalamiento y Monitoreo CloudWatch
# ==============================================================================

# Auto Scaling Group Multi-AZ (Min: 1 | Deseada: 1 | Max: 3)
resource "aws_autoscaling_group" "main" {
  name                = "asg-${var.project_name}"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  health_check_type   = "ELB"
  health_check_grace_period = 300

  vpc_zone_identifier = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1b.id,
    aws_subnet.public_1c.id
  ]

  target_group_arns = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      max_healthy_percentage = 200
    }
    triggers = ["tag"]
  }

  tag {
    key                 = "Name"
    value               = "ec2-${var.project_name}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "InstanceType"
    value               = var.instance_type
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Política de Escalamiento Target Tracking (CPU = 50%)
# Ajusta automáticamente el número de instancias entre 1 y 3 para mantener el CPU al 50%
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "asp-${var.project_name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target_utilization
  }
}

# Política de Escalamiento Rápido (+1 instancia en alarma de CPU alta)
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "asp-${var.project_name}-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.main.name
}

# Alarma de CloudWatch para Observabilidad y Escalamiento Rápido (CPUUtilization > 50%)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "alarm-${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_target_utilization
  alarm_description   = "Disparada cuando el uso promedio de CPU en el ASG supera el 50%"
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}

# Política de Reducción Rápida (-1 instancia cuando la CPU desciende)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "asp-${var.project_name}-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.main.name
}

# Alarma de CloudWatch para Reducción Rápida (CPUUtilization < 25% durante 1 minuto)
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "alarm-${var.project_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 25.0
  alarm_description   = "Disparada cuando el uso promedio de CPU en el ASG desciende por debajo del 25% por 1 minuto"
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}
