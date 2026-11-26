# ==============================================================================
# Backend Remoto — Estado en S3
# El bucket lo pasa el pipeline con -backend-config=bucket=... en el terraform init.
# Nombre del bucket: cascos-ultra-estado-<ACCOUNT_ID>  (creado por bootstrap/).
# ==============================================================================
terraform {
  backend "s3" {
    key          = "terraform.tfstate"
    encrypt      = true
    use_lockfile = true
    # bucket y region los inyecta el pipeline (plan.yml / apply.yml)
  }
}
