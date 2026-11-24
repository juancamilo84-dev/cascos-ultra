---
name: aws-infra-cascos-ultra
description: >-
  Runbook completo de la infraestructura AWS de Cascos Ultra. Usar cuando el usuario
  pide desplegar, modificar, debuggear o verificar la infraestructura AWS del proyecto
  Cascos Ultra: EC2, ASG, ALB, CloudWatch, Terraform. Incluye errores conocidos,
  soluciones probadas y procedimientos paso a paso.
---

# Cascos Ultra — Runbook de Infraestructura AWS

Lee también los archivos de referencia detallados en `references/` si necesitas más detalle:
- [Errores conocidos y fixes](./references/errores-conocidos.md)
- [Arquitectura completa](./references/arquitectura.md)
- [Procedimientos de operación](./references/operaciones.md)

---

## Resumen Rápido

- **App:** E-commerce de cascos con demo de Auto Scaling en vivo
- **Stack:** Terraform + AWS (EC2, ASG, ALB, CloudWatch, VPC)
- **Región:** `us-east-1`
- **Free Tier:** Usar **`t3.micro`** (NO `t2.micro` — no es elegible en esta cuenta)

## Archivos Clave del Proyecto

```
cascos-ultra/
├── terraform/
│   ├── main.tf          # Provider y configuración base
│   ├── variables.tf     # instance_type = "t3.micro"
│   ├── asg.tf           # ASG, Launch Template, políticas de escalado, alarmas CW
│   ├── alb.tf           # Application Load Balancer
│   ├── vpc.tf           # VPC, subnets, security groups
│   ├── outputs.tf       # ALB DNS, etc.
│   └── userdata.sh      # Script de inicialización de instancias EC2
├── index.html           # App frontend (descargada desde GitHub en boot)
└── .agents/
    └── skills/
        └── aws-infra-cascos-ultra/  ← esta skill
```

## Comandos de Terraform

```powershell
# SIEMPRE con BypassSandbox: true
cd C:\Users\Camilo\cascos-ultra\terraform

terraform init
terraform plan -lock=false
terraform apply -lock=false -auto-approve
terraform destroy -lock=false -auto-approve
```

## Verificación Rápida del Estado

```powershell
# Estado del ASG
powershell.exe -ExecutionPolicy Bypass -File "C:\...\scratch\check_asg.ps1"

# Alarmas CloudWatch
powershell.exe -ExecutionPolicy Bypass -File "C:\...\scratch\check_alarms.ps1"

# ALB health
curl.exe -s "http://alb-cascos-ultra-1638640101.us-east-1.elb.amazonaws.com/api/system"
```

## Cómo Funciona el Auto Scaling

| Componente | Configuración |
|------------|---------------|
| ASG min/max | 1 / 3 instancias |
| Alarm cpu-high | CPU > 50% por 1 período (60s) → scale out +1 |
| Alarm cpu-low | CPU < 25% por 1 período (60s) → scale in -1 |
| Cooldown | 60 segundos |
| Stress test | `stress-ng` corriendo 300s desde la UI |

## Demo End-to-End

1. Abrir `http://alb-cascos-ultra-1638640101.us-east-1.elb.amazonaws.com`
2. Click **"🔥 Disparar Estrés CPU"** → esperar ~1-2 min → aparece 2do nodo
3. Click **"⏹ Detener"** → esperar ~1-2 min → vuelve a 1 nodo
4. Click **"🔄 Probar Balanceo ALB"** → muestra load balancing cambiando instance ID
