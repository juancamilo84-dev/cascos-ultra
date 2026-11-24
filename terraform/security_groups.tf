# ==============================================================================
# Security Groups (Grupos de Seguridad)
# ==============================================================================

# 1. Security Group para el Application Load Balancer
# Expone el puerto 80 a Internet
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Permite trafico HTTP publico hacia el ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Permite salida a cualquier destino"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-${var.project_name}-alb"
  }
}

# 2. Security Group para las Instancias EC2 del Auto Scaling Group
# Permite tráfico HTTP :80 EXCLUSIVAMENTE proveniente del ALB
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Permite trafico HTTP exclusivamente desde el ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP exclusivamente desde el ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Salida total para descarga de paquetes (dnf, NGINX) e IMDSv2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-${var.project_name}-ec2"
  }
}
