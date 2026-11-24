#!/bin/bash
# ==============================================================================
# User Data Script para Amazon Linux 2023 - Cascos Ultra (Black Friday)
# Configura el Servidor Web (NGINX), el Servidor de Aplicación (Python Microservice)
# y el Monitor de Procesos del Sistema Operativo en Tiempo Real
# ==============================================================================

# 1. Actualizar sistema e instalar NGINX, utilidades y monitor
dnf install -y nginx stress-ng python3 procps-ng

# 2. Consultar AWS IMDSv2 (Instance Metadata Service v2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
LOCAL_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

# Guardar variables de entorno para servicios
cat <<ENVFILE > /etc/cascos.env
INSTANCE_ID=$INSTANCE_ID
AZ=$AZ
LOCAL_IP=$LOCAL_IP
ENVFILE

# 3. Crear el Servidor de Aplicación (Backend de Procesos y Telemetría en Python)
mkdir -p /opt/cascos

cat <<'PYEOF' > /opt/cascos/server.py
import http.server
import socketserver
import subprocess
import json
import os
import time

PORT = 5000

class CascosAPIHandler(http.server.BaseHTTPRequestHandler):
    def _send_json(self, data, status=200):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def do_OPTIONS(self):
        self._send_json({})

    def do_GET(self):
        if self.path == '/api/system':
            uptime_text = "En línea"
            try:
                with open('/proc/uptime', 'r') as f:
                    uptime_seconds = float(f.readline().split()[0])
                    hours = int(uptime_seconds // 3600)
                    minutes = int((uptime_seconds % 3600) // 60)
                    uptime_text = f"{hours}h {minutes}m"
            except Exception:
                pass

            ram_text = "N/A"
            try:
                with open('/proc/meminfo', 'r') as f:
                    mem = {}
                    for line in f:
                        parts = line.split(':')
                        if len(parts) == 2:
                            mem[parts[0].strip()] = int(parts[1].strip().split()[0])
                    total_mb = mem.get('MemTotal', 1) // 1024
                    avail_mb = mem.get('MemAvailable', 0) // 1024
                    used_mb = total_mb - avail_mb
                    ram_text = f"{used_mb} MB / {total_mb} MB"
            except Exception:
                pass

            cpu_val = 15.0
            try:
                out = subprocess.check_output("ps -A -o %cpu | awk '{s+=$1} END {print s}'", shell=True).decode().strip()
                cpu_val = float(out) if out else 15.0
            except Exception:
                pass

            data = {
                "instance_id": os.environ.get("INSTANCE_ID", "i-unknown"),
                "az": os.environ.get("AZ", "us-east-1a"),
                "local_ip": os.environ.get("LOCAL_IP", "127.0.0.1"),
                "cpu_percent": cpu_val,
                "ram_text": ram_text,
                "uptime_text": uptime_text,
                "timestamp": int(time.time())
            }
            self._send_json(data)

        elif self.path == '/api/processes':
            processes = []
            try:
                cmd = "ps -eo pid,user,%cpu,%mem,stat,comm --sort=-%cpu | head -n 35"
                output = subprocess.check_output(cmd, shell=True).decode('utf-8')
                lines = output.strip().split('\n')
                for line in lines[1:]:
                    parts = line.split(None, 5)
                    if len(parts) >= 6:
                        processes.append({
                            "pid": int(parts[0]) if parts[0].isdigit() else parts[0],
                            "user": parts[1],
                            "cpu": parts[2],
                            "mem": parts[3],
                            "stat": parts[4],
                            "comm": parts[5]
                        })
            except Exception as e:
                processes = [{"pid": 0, "user": "err", "cpu": 0, "mem": 0, "stat": "E", "comm": str(e)}]
            self._send_json({"processes": processes})

        else:
            self._send_json({"error": "Endpoint no encontrado"}, status=404)

    def do_POST(self):
        if self.path == '/api/stress':
            try:
                subprocess.Popen(["stress-ng", "--cpu", "2", "--timeout", "300s"])
                self._send_json({"status": "stress_started", "duration": 300})
            except Exception as e:
                self._send_json({"status": "error", "message": str(e)}, status=500)
        elif self.path == '/api/stress/stop':
            try:
                subprocess.run(["pkill", "-9", "stress-ng"], check=False)
                self._send_json({"status": "stress_stopped"})
            except Exception as e:
                self._send_json({"status": "error", "message": str(e)}, status=500)
        else:
            self._send_json({"error": "Endpoint no encontrado"}, status=404)

class ThreadedHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True

if __name__ == '__main__':
    server = ThreadedHTTPServer(('127.0.0.1', PORT), CascosAPIHandler)
    server.serve_forever()
PYEOF

# 4. Configurar e Iniciar Servicio Systemd para el Backend de Aplicación
cat <<'SERVICE' > /etc/systemd/system/cascos-backend.service
[Unit]
Description=Cascos Ultra Application Server & Process Monitor
After=network.target

[Service]
Type=simple
User=root
EnvironmentFile=/etc/cascos.env
ExecStart=/usr/bin/python3 /opt/cascos/server.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable cascos-backend
systemctl start cascos-backend

# 5. Configurar NGINX como Servidor Web y Reverse Proxy para /api/
mkdir -p /etc/nginx/conf.d
cat <<EOF > /etc/nginx/conf.d/cascos.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    add_header X-Served-By "$INSTANCE_ID" always;
    add_header X-Availability-Zone "$AZ" always;
    add_header X-Local-IP "$LOCAL_IP" always;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_connect_timeout 5s;
        proxy_read_timeout 15s;
    }
}
EOF

# Remover configuración por defecto que pueda entrar en conflicto
rm -f /etc/nginx/conf.d/default.conf

# 6. Descargar el Frontend interactivo directamente desde el repositorio
mkdir -p /usr/share/nginx/html

curl -s -L https://raw.githubusercontent.com/DanyArias/cascos-ultra/main/index.html -o /tmp/template.html

# Sustituir placeholders por metadatos reales de IMDSv2
sed -e "s/__INSTANCE_ID__/$INSTANCE_ID/g" \
    -e "s/__AZ__/$AZ/g" \
    -e "s/__LOCAL_IP__/$LOCAL_IP/g" \
    /tmp/template.html > /usr/share/nginx/html/index.html

# 7. Iniciar y habilitar NGINX
systemctl restart nginx
systemctl enable nginx
