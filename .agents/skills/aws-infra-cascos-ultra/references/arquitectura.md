# Arquitectura AWS — Cascos Ultra

## Diagrama General

```
Internet
    │
    ▼
[ALB - Application Load Balancer]
alb-cascos-ultra-1638640101.us-east-1.elb.amazonaws.com
    │
    ▼
[Target Group: tg-cascos-ultra]
arn:aws:elasticloadbalancing:us-east-1:715054189423:targetgroup/tg-cascos-ultra/cc699c28f76ada29
    │
    ├── [EC2 t3.micro - us-east-1a - subnet pública]
    ├── [EC2 t3.micro - us-east-1b - subnet pública]  ← instancia principal actual
    └── [EC2 t3.micro - us-east-1c - subnet pública]
         (1-3 instancias según demanda)

[Auto Scaling Group: asg-cascos-ultra]
  - Min: 1 | Desired: 1 | Max: 3
  - Launch Template: lt-083892ef936cd0a26

[CloudWatch Alarms]
  - alarm-cascos-ultra-cpu-high: CPU > 50% por 60s → scale out +1
  - alarm-cascos-ultra-cpu-low:  CPU < 25% por 60s → scale in  -1

[VPC: vpc-0bdea5c7a3bc22439]
  CIDR: 10.0.0.0/16
  - Subnet pública us-east-1a: 10.0.1.0/24
  - Subnet pública us-east-1b: 10.0.2.0/24
  - Subnet pública us-east-1c: 10.0.3.0/24
```

## Stack de Software por Instancia EC2

```
Amazon Linux 2023
└── Nginx (reverse proxy, puerto 80)
    └── Node.js / Python app (puerto interno)
        └── index.html (descargado desde GitHub al arrancar)
            ├── API /api/system  → datos de IMDSv2 (instance ID, AZ, IP, CPU, RAM)
            ├── API /api/stress  → lanza stress-ng 300s
            └── API /api/stop    → mata stress-ng
```

## Flujo de Arranque de una Instancia (userdata.sh)

1. Instala dependencias: nginx, node, stress-ng, python3
2. Descarga `index.html` desde `https://raw.githubusercontent.com/DanyArias/cascos-ultra/main/index.html`
3. Configura y arranca nginx
4. Arranca el servidor backend (Node.js/Python) en puerto interno
5. Instancia disponible en el Target Group tras el health check del ALB

## Políticas de Auto Scaling

### Scale Out (añadir nodo)
- **Trigger:** `alarm-cascos-ultra-cpu-high` → CPU promedio del ASG > 50% por 1 período de 60s
- **Acción:** `scale-out-cascos-ultra` policy → `ChangeInCapacity +1`
- **Cooldown:** 60 segundos

### Scale In (quitar nodo)
- **Trigger:** `alarm-cascos-ultra-cpu-low` → CPU promedio del ASG < 25% por 1 período de 60s
- **Acción:** `scale-in-cascos-ultra` policy → `ChangeInCapacity -1`
- **Cooldown:** 60 segundos

## Archivos Terraform

| Archivo | Contenido |
|---------|-----------|
| `main.tf` | Provider AWS, región us-east-1 |
| `variables.tf` | `instance_type = "t3.micro"`, otras variables |
| `vpc.tf` | VPC, subnets, internet gateway, route tables, security groups |
| `alb.tf` | ALB, listener HTTP:80, target group, health check |
| `asg.tf` | Launch Template, ASG, scaling policies, CloudWatch alarms |
| `userdata.sh` | Script de inicialización de instancias |
| `outputs.tf` | Outputs: ALB DNS name, etc. |

## Notas de Free Tier

- **`t3.micro`**: Free Tier eligible en esta cuenta AWS ✅
- **`t2.micro`**: NO elegible en esta cuenta ❌ (causa error de lanzamiento en el ASG)
- El Free Tier de AWS cubre 750 horas/mes de t3.micro — con 1 instancia permanente no hay costo.
- Con 3 instancias corriendo simultáneamente se consume el free tier en ~10 días.
