variable "aws_region" {
  description = "Región de AWS donde se desplegarán todos los recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo identificador para los recursos del proyecto"
  type        = string
  default     = "cascos-ultra"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC principal"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "Bloque CIDR para la subred pública 1A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "Bloque CIDR para la subred pública 1B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "public_subnet_c_cidr" {
  description = "Bloque CIDR para la subred pública 1C"
  type        = string
  default     = "10.0.3.0/24"
}

variable "az_a" {
  description = "Zona de disponibilidad A"
  type        = string
  default     = "us-east-1a"
}

variable "az_b" {
  description = "Zona de disponibilidad B"
  type        = string
  default     = "us-east-1b"
}

variable "az_c" {
  description = "Zona de disponibilidad C"
  type        = string
  default     = "us-east-1c"
}

variable "instance_type" {
  description = "Tipo de instancia EC2 elegible para AWS Free Tier (en esta cuenta: t3.micro)"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Capacidad mínima del Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Capacidad máxima del Auto Scaling Group"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Capacidad deseada inicial del Auto Scaling Group"
  type        = number
  default     = 1
}

variable "cpu_target_utilization" {
  description = "Porcentaje de CPU objetivo para la política de Target Tracking"
  type        = number
  default     = 50.0
}
