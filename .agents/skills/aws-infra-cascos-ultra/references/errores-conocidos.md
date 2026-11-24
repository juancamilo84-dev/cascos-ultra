# Errores Conocidos y Fixes — Cascos Ultra AWS

## 1. ❌ `t2.micro` no es Free Tier en esta cuenta

**Error:**
```
The specified instance type is not eligible for Free Tier.
```

**Causa:** Esta cuenta AWS tiene `t3.micro` como Free Tier eligible, NO `t2.micro`.

**Fix:** En `terraform/variables.tf`:
```hcl
variable "instance_type" {
  default     = "t3.micro"
  description = "Free Tier eligible en esta cuenta (NO t2.micro)"
}
```

**Verificación:**
```powershell
# Para verificar qué tipos son Free Tier en la cuenta:
# AWS Console → EC2 → Launch Instance → buscar "free tier eligible"
```

---

## 2. ❌ Error de state lock en Terraform

**Error:**
```
Error acquiring the state lock: open terraform.tfstate: Acceso denegado
```

**Causa:** El sandbox de AGY tiene restricciones de permisos sobre el archivo `terraform.tfstate`.

**Fix:** Agregar `-lock=false` a todos los comandos terraform:
```powershell
terraform plan -lock=false
terraform apply -lock=false -auto-approve
```

---

## 3. ❌ Terraform no puede cargar plugins (sin red)

**Error:**
```
Failed to load plugin schemas: Plugin did not respond
```

**Causa:** El sandbox estándar de AGY NO tiene acceso de red. Terraform necesita red para comunicarse con AWS.

**Fix:** SIEMPRE ejecutar comandos Terraform con `BypassSandbox: true` en AGY.

---

## 4. ❌ No hay credenciales AWS

**Error:**
```
No valid credential sources found
```

**Fix:** Configurar credenciales:
```powershell
# Crear C:\Users\Camilo\.aws\credentials
[default]
aws_access_key_id = AKIA2M7ENBNXSOT2C6TA
aws_secret_access_key = <valor del CSV>

# Crear C:\Users\Camilo\.aws\config
[default]
region = us-east-1
output = json
```

Origen: `C:\Users\Camilo\Downloads\admin_accessKeys.csv`

---

## 5. ❌ `instance_refresh` error de porcentaje

**Error:**
```
MaxHealthyPercentage - MinHealthyPercentage must be <= 100
```

**Causa:** Configuración inválida de `instance_refresh` en el ASG.

**Fix en `terraform/asg.tf`:**
```hcl
instance_refresh {
  strategy = "Rolling"
  preferences {
    min_healthy_percentage = 100
    max_healthy_percentage = 200
  }
  triggers = ["tag"]
}
```

---

## 6. ❌ ASG no escala hacia abajo

**Síntoma:** El número de nodos no baja aunque el CPU esté bajo.

**Causa raíz:** No existía una política de scale-in ni una alarma `cpu-low`. El TargetTracking por defecto requiere 15 períodos consecutivos (15 min) para escalar hacia abajo.

**Fix aplicado en `terraform/asg.tf`:**
```hcl
# Política de scale-in
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in-cascos-ultra"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

# Alarma CPU baja → scale in
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "alarm-cascos-ultra-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 25
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}
```

---

## 7. ❌ Stress test termina antes que CloudWatch detecte el problema

**Síntoma:** El CPU sube pero vuelve a bajar antes de que el ASG reaccione.

**Causa:** `stress-ng` corría solo 60 segundos. CloudWatch necesita al menos 1 período completo de 60s con CPU > 50%.

**Fix:** Extender duración a 300 segundos en `userdata.sh`:
```bash
stress-ng --cpu 0 --cpu-load 85 --timeout 300s
```

Y en `index.html` actualizar el countdown a 300s.

**Importante:** Los cambios en `userdata.sh` solo aplican a **nuevas instancias**. Las existentes mantienen el script anterior.

---

## 8. ❌ `index.html` local no se refleja en el servidor

**Causa:** El `userdata.sh` descarga `index.html` desde GitHub al arrancar la instancia:
```bash
curl -o /var/www/html/index.html https://raw.githubusercontent.com/DanyArias/cascos-ultra/main/index.html
```

**Fix:** Para actualizar el HTML en servidores en vivo, hay que hacer push a la rama `main` del repo `DanyArias/cascos-ultra` en GitHub. O lanzar nuevas instancias (que descargarán el nuevo HTML al arrancar).

---

## 9. ❌ PowerShell variables con `$` no pasan bien en `-Command`

**Síntoma:** Variables `$p`, `$xml`, `$asg` aparecen vacías o hay errores de parser.

**Fix:** Usar un script `.ps1` temporal en lugar de `-Command "..."` con variables complejas:
```powershell
# Crear script en scratch/, luego:
powershell.exe -ExecutionPolicy Bypass -File "C:\...\scratch\mi_script.ps1"
```
