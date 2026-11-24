# ==============================================================================
# Launch Template (Plantilla de Lanzamiento para Instancias EC2)
# ==============================================================================

# Obtener la última AMI oficial de Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Plantilla de Lanzamiento lt-cascos-ultra
resource "aws_launch_template" "main" {
  name_prefix   = "lt-${var.project_name}-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # User data codificado en base64 para auto-aprovisionamiento e inyección de metadatos IMDSv2
  user_data = filebase64("${path.module}/userdata.sh")

  # Configuración estricta de IMDSv2 requerida por la arquitectura
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 obligatorio
    http_put_response_hop_limit = 2
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ec2-${var.project_name}"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "lt-${var.project_name}"
  }
}
