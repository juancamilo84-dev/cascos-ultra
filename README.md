# Cascos Ultra — Arquitectura de Escalamiento Horizontal en AWS

Proyecto de comercio electrónico para el evento **Black Friday de Cascos Ultra**, diseñado para demostrar la alta disponibilidad (Multi-AZ), balanceo de carga (ALB) y escalamiento automático horizontal (Auto Scaling Group) con observabilidad en tiempo real y elegibilidad 100% para **AWS Free Tier**.

## Características Principales

1. **Frontend Interactivo 100% Funcional ([index.html](index.html))**:
   - **Tienda Black Friday**: Catálogo de cascos de fibra de carbono con filtrado dinámico por categoría (Pista, Touring, Enduro, Urbano).
   - **Carrito de Compras Completo**: Control de cantidades, cálculo de totales en tiempo real y checkout interactivo.
   - **Panel de Telemetría AWS**: Detección dinámica de metadatos vía **IMDSv2** (`Instance ID`, `Availability Zone`, `IP Privada`), tiempo activo (*uptime*), y medidores de CPU y Memoria RAM.
   - **Monitor de Procesos del Sistema Operativo**: Tabla en vivo con los procesos activos del servidor (`ps -eo pid,user,%cpu,%mem,stat,comm`), filtro por texto/PID, insignias de estado y actualización automática cada 2 segundos.
   - **Controlador de Estrés de CPU**: Botones para disparar y detener pruebas de carga (`stress-ng`), simulando la sobrecarga necesaria para activar la alarma de CloudWatch y el Auto Scaling Group.

2. **Servidor de Aplicación & Backend ([userdata.sh](userdata.sh))**:
   - Microservicio liviano en Python (`/opt/cascos/server.py`) ejecutado bajo Systemd (`cascos-backend.service`).
   - Expone endpoints REST en `/api/`:
     - `GET /api/system`: Métricas de CPU, RAM, Uptime e identificación IMDSv2.
     - `GET /api/processes`: Lista de procesos en tiempo real ordenados por consumo de CPU.
     - `POST /api/stress`: Ejecuta `stress-ng` para sobrecargar el procesador al 100% y probar el escalamiento.
     - `POST /api/stress/stop`: Termina el proceso de estrés.
   - Servidor Web NGINX configurado como reverse proxy inverso para `/api/` y entrega de estáticos con inyección de headers (`X-Served-By`, `X-Availability-Zone`, `X-Local-IP`).

3. **Infraestructura como Código ([terraform/](terraform/))**:
   - Módulos organizados para desplegar la VPC (Multi-AZ con 3 subredes públicas), Application Load Balancer, Launch Template, Target Tracking ASG y CloudWatch Alarms.

4. **Diagrama de Arquitectura Interactivo ([diagrama_arquitectura.html](diagrama_arquitectura.html))**:
   - Diagrama interactivo y diagrama formal en Mermaid.js con simulación visual de la ráfaga de tráfico y escalamiento de 1 a 3 instancias.
