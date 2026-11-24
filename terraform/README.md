# Infraestructura como Código (Terraform) — Cascos Ultra

Este módulo de Terraform despliega la arquitectura completa descrita en el [diagrama de arquitectura](../diagrama_arquitectura.html) para el evento **Black Friday de Cascos Ultra**, diseñada para alta disponibilidad (Multi-AZ) y compatibilidad con el nivel gratuito (**AWS Free Tier**).

## Recursos Desplegados

1. **VPC y Networking (`vpc.tf`)**:
   - VPC `vpc-cascos-ultra` (`10.0.0.0/16`) con soporte y nombres DNS activos.
   - Internet Gateway `igw-cascos-ultra`.
   - 3 Subredes Públicas Multi-AZ:
     - `subnet-cascos-public-1a` (`10.0.1.0/24` en `us-east-1a`).
     - `subnet-cascos-public-1b` (`10.0.2.0/24` en `us-east-1b`).
     - `subnet-cascos-public-1c` (`10.0.3.0/24` en `us-east-1c`).
   - Tabla de enrutamiento con salida a Internet `0.0.0.0/0 -> IGW`.

2. **Seguridad (`security_groups.tf`)**:
   - `sg-cascos-alb`: Permite tráfico HTTP (`:80`) público desde Internet (`0.0.0.0/0`).
   - `sg-cascos-ec2`: Permite tráfico HTTP (`:80`) **exclusivamente** desde el Security Group del balanceador (`sg-cascos-alb`), impidiendo el bypass directo.

3. **Plantilla de Lanzamiento (`launch_template.tf`)**:
   - AMI Amazon Linux 2023 dinámica.
   - Instancias `t2.micro` (Free Tier).
   - Script `userdata.sh` que instala NGINX, consulta IMDSv2 e inyecta dinámicamente el `Instance ID`, `Availability Zone` e `IP Local` en la interfaz web servida.
   - Forzado de IMDSv2 (`http_tokens = "required"`).

4. **Application Load Balancer (`alb.tf`)**:
   - `alb-cascos-ultra` desplegado a través de las 3 subredes públicas.
   - `tg-cascos-ultra` Target Group con comprobaciones de estado periódicas (`/`).
   - Listener HTTP `:80` que redirige el tráfico hacia el Target Group.

5. **Auto Scaling y Observabilidad (`asg.tf`)**:
   - Auto Scaling Group `asg-cascos-ultra` (Mínimo: 1, Deseada: 1, Máximo: 3).
   - Política **Target Tracking** que monitorea el uso promedio de CPU (`ASGAverageCPUUtilization = 50%`) y escala automáticamente horizontalmente.
   - Alarma de CloudWatch `alarm-cascos-ultra-cpu-high` para observabilidad.

## Uso

```bash
# 1. Inicializar proveedores
terraform init

# 2. Validar sintaxis y configuración
terraform validate

# 3. Planificar despliegue
terraform plan

# 4. Aplicar infraestructura
terraform apply
```
