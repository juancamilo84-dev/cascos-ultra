# Cascos Ultra — Contexto del Proyecto AWS

Este es el proyecto **Cascos Ultra**, una tienda e-commerce desplegada en AWS con infraestructura gestionada por **Terraform**. Este archivo se carga automáticamente en cada conversación AGY en este workspace.

## Datos Críticos de Infraestructura

| Recurso | Valor |
|---------|-------|
| **ALB DNS** | `http://alb-cascos-ultra-1638640101.us-east-1.elb.amazonaws.com` |
| **ASG Name** | `asg-cascos-ultra` |
| **Launch Template** | `lt-083892ef936cd0a26` |
| **VPC** | `vpc-0bdea5c7a3bc22439` |
| **Target Group ARN** | `arn:aws:elasticloadbalancing:us-east-1:715054189423:targetgroup/tg-cascos-ultra/cc699c28f76ada29` |
| **AWS Account** | `715054189423` |
| **Región** | `us-east-1` |
| **Instance Type** | `t3.micro` (Free Tier en esta cuenta) |

## Credenciales AWS

- Archivo: `C:\Users\Camilo\.aws\credentials` y `C:\Users\Camilo\.aws\config`
- Access Key ID: `AKIA2M7ENBNXSOT2C6TA`
- Origen: `C:\Users\Camilo\Downloads\admin_accessKeys.csv`

## Reglas Obligatorias

1. **SIEMPRE usar `t3.micro`** para instancias EC2 — `t2.micro` NO es Free Tier en esta cuenta.
2. **TODOS los comandos Terraform y AWS requieren `BypassSandbox: true`** (el sandbox no tiene acceso de red).
3. **Terraform state es local** en `terraform/terraform.tfstate` — usar `-lock=false` si hay error de lock.
4. **Terraform siempre con `-lock=false`** cuando hay problemas de permisos en el sandbox.
5. **Responder siempre en español** al usuario.

## Helper Script AWS

Existe un script PowerShell firmado AWS4 en:
`C:\Users\Camilo\.gemini\antigravity-cli\brain\8088c21e-52a9-46e6-9435-b7dc0cf81535\scratch\aws_query.ps1`

Uso:
```powershell
# Siempre con BypassSandbox: true
$p = @{'AutoScalingGroupName.member.1'='asg-cascos-ultra'}
$xml = [xml](& 'C:\...\aws_query.ps1' -Service 'autoscaling' -Action 'DescribeAutoScalingGroups' -CustomParams $p)
```

Servicios soportados: `autoscaling`, `ec2`, `monitoring`, `elasticloadbalancing`

## Skill Disponible

Carga la skill `aws-infra-cascos-ultra` para ver el runbook completo de operaciones, errores conocidos y procedimientos de despliegue.
