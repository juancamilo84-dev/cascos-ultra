# Procedimientos de Operación — Cascos Ultra AWS

## Prerequisitos

- AGY workspace: `C:\Users\Camilo\cascos-ultra`
- Credenciales AWS en `C:\Users\Camilo\.aws\credentials`
- **Todos los comandos AWS/Terraform requieren `BypassSandbox: true`**
- Helper script: `C:\Users\Camilo\.gemini\antigravity-cli\brain\8088c21e-52a9-46e6-9435-b7dc0cf81535\scratch\aws_query.ps1`

---

## Procedimiento: Despliegue Inicial

```powershell
# 1. Ir al directorio terraform
cd C:\Users\Camilo\cascos-ultra\terraform

# 2. Inicializar (solo primera vez o tras cambiar providers)
terraform init

# 3. Revisar plan
terraform plan -lock=false

# 4. Aplicar
terraform apply -lock=false -auto-approve

# 5. Verificar ALB
curl.exe -s "http://alb-cascos-ultra-1638640101.us-east-1.elb.amazonaws.com/api/system"
```

**Tiempo estimado:** 3-5 minutos para que las instancias pasen los health checks del ALB.

---

## Procedimiento: Verificar Estado del ASG

```powershell
# Usar script helper
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\Camilo\.gemini\antigravity-cli\brain\8088c21e-52a9-46e6-9435-b7dc0cf81535\scratch\check_asg.ps1"

# Output esperado (estado normal):
# Desired: 1  Min: 1  Max: 3
#   Instance: i-xxxxxxxxxx  State: InService  Health: Healthy
```

---

## Procedimiento: Verificar Alarmas CloudWatch

```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\Camilo\.gemini\antigravity-cli\brain\8088c21e-52a9-46e6-9435-b7dc0cf81535\scratch\check_alarms.ps1"

# Output esperado (estado normal, 1 nodo sin estrés):
# Alarm: alarm-cascos-ultra-cpu-high  State: OK     Threshold: 50.0  Comparison: GreaterThanThreshold
# Alarm: alarm-cascos-ultra-cpu-low   State: ALARM  Threshold: 25.0  Comparison: LessThanThreshold
#   (cpu-low en ALARM es NORMAL cuando hay 1 sola instancia sin carga — no puede bajar más del mínimo)
```

---

## Procedimiento: Demo de Auto Scaling

### Escalar hacia arriba (scale out)
1. Abrir `http://alb-cascos-ultra-1638640101.us-east-1.elb.amazonaws.com`
2. Click en **"🔥 Disparar Estrés CPU"**
3. Esperar ~60-90 segundos
4. CloudWatch detecta CPU > 50% → alarma `cpu-high` → scale out +1
5. Nueva instancia aparece en el ASG (~2-3 min para quedar InService)
6. Refrescar la página → el Instance ID cambia entre los nodos

### Escalar hacia abajo (scale in)
1. Click en **"⏹ Detener"** (o esperar que el stress termine a los 300s)
2. Esperar ~60 segundos
3. CloudWatch detecta CPU < 25% → alarma `cpu-low` → scale in -1
4. Instancia extra pasa a Terminating
5. Vuelve a 1 instancia activa

---

## Procedimiento: Cambiar Tipo de Instancia

> **IMPORTANTE:** Siempre usar `t3.micro`. Nunca cambiar a `t2.micro`.

```hcl
# terraform/variables.tf
variable "instance_type" {
  default     = "t3.micro"
  description = "Free Tier eligible en esta cuenta (NO t2.micro)"
}
```

Tras cambiar el tipo:
1. `terraform apply -lock=false -auto-approve`
2. Terraform actualiza el Launch Template
3. El Instance Refresh reemplaza instancias gradualmente (rolling)

---

## Procedimiento: Forzar Reemplazo de Instancias

Si hay instancias con configuración vieja que necesitas reemplazar:

```powershell
# En terraform/asg.tf, cambiar el tag "InstanceType" a un valor nuevo
# Esto dispara instance_refresh porque triggers = ["tag"]
# Luego:
terraform apply -lock=false -auto-approve
```

---

## Procedimiento: Ver Logs de una Instancia

```powershell
# Usando SSM Session Manager (si está configurado)
# O via AWS Console → EC2 → Connect → Session Manager

# Ver logs de userdata:
sudo cat /var/log/cloud-init-output.log

# Ver logs de nginx:
sudo journalctl -u nginx -n 50

# Ver proceso stress-ng activo:
ps aux | grep stress
```

---

## Procedimiento: Destruir Infraestructura

```powershell
cd C:\Users\Camilo\cascos-ultra\terraform
terraform destroy -lock=false -auto-approve
```

**Tiempo estimado:** 2-5 minutos.
⚠️ Esto elimina TODOS los recursos: EC2, ALB, ASG, VPC, security groups.

---

## Procedimiento: Recrear Helper Scripts

Si los scripts helper se pierden, recrearlos en:
`C:\Users\Camilo\.gemini\antigravity-cli\brain\8088c21e-52a9-46e6-9435-b7dc0cf81535\scratch\`

Scripts necesarios:
- `aws_query.ps1` — Firmador AWS4 Signature para llamadas API directas
- `check_asg.ps1` — Muestra estado del ASG
- `check_alarms.ps1` — Muestra estado de alarmas CloudWatch

El script `aws_query.ps1` usa AWS Signature Version 4 con las credenciales de `~/.aws/credentials`.

---

## Referencia Rápida de Comandos AWS API (vía aws_query.ps1)

```powershell
# Describir ASG
$p = @{'AutoScalingGroupName.member.1'='asg-cascos-ultra'}
& 'C:\...\aws_query.ps1' -Service 'autoscaling' -Action 'DescribeAutoScalingGroups' -CustomParams $p

# Describir alarmas
$p = @{'AlarmNames.member.1'='alarm-cascos-ultra-cpu-high'; 'AlarmNames.member.2'='alarm-cascos-ultra-cpu-low'}
& 'C:\...\aws_query.ps1' -Service 'monitoring' -Action 'DescribeAlarms' -CustomParams $p

# Describir instancias EC2
$p = @{'Filter.1.Name'='tag:aws:autoscaling:groupName'; 'Filter.1.Value.1'='asg-cascos-ultra'}
& 'C:\...\aws_query.ps1' -Service 'ec2' -Action 'DescribeInstances' -CustomParams $p

# Describir target group health
$p = @{'TargetGroupArn'='arn:aws:elasticloadbalancing:us-east-1:715054189423:targetgroup/tg-cascos-ultra/cc699c28f76ada29'}
& 'C:\...\aws_query.ps1' -Service 'elasticloadbalancing' -Action 'DescribeTargetHealth' -CustomParams $p
```
