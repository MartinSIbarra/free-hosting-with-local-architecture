#!/bin/bash
# Seteo de url para el repositorio remote de los scripts
remote_repo="https://raw.githubusercontent.com/MartinSIbarra/localhost-configs/refs/heads/main/files"
export REMOTE_REPO=$remote_repo

# Valores por defecto
server_type=""
ngrok_auth_token=""
ngrok_tunnel_url=""

# Procesar argumentos
for arg in "$@"; do
  case $arg in
    --server-type=*) server_type="${arg#*=}" ;;
    --ngrok-auth-token=*) ngrok_auth_token="${arg#*=}" ;;
    --ngrok-tunnel-url=*) ngrok_tunnel_url="${arg#*=}" ;;
    --help)
      echo ""
      echo "  Uso: $0 --server-type=<tipo> [--ngrok-auth-token=<token>] [--ngrok-tunnel-url=<url>]"
      echo ""
      echo "  --server-type:        Tipos de servidor permitidos: devops, prod, uat"
      echo "  --ngrok-auth-token:   Token de autenticación para ngrok (obligatorio para --server-type=devops)"
      echo "  --ngrok-tunnel-url:   URL del túnel ngrok (obligatorio para --server-type=devops)"
      echo ""
      exit 0
      ;;
    *)
      echo "Argumento no reconocido: $arg, use --help para ver la ayuda."
      exit 1
      ;;
  esac
done

# Se valida el parametro server-type y en el caso de ser devops se valida el token y la url
case "$server_type" in
  devops)
    if [ -z "$ngrok_auth_token" ]; then
      echo "El argumento --ngrok-auth-token es obligatorio para el --server-type=devops"
      exit 1
    fi
    if [ -z "$ngrok_tunnel_url" ]; then
      echo "El argumento --ngrok-tunnel-url es obligatorio para el --server-type=devops"
      exit 1
    fi
    shift
    ;;
  prod|uat) ;;
  *) 
    echo "Los valores permitidos para --server-type son: devops, prod, uat"
    exit 1
    ;;
esac

export NGROK_AUTH_TOKEN=$ngrok_auth_token
export NGROK_TUNNEL_URL=$ngrok_tunnel_url

# Metodo helper para ejecutar comandos y reintentar en caso de error
exec_until_done() {
  local n=0
  local max=10
  local delay=5

  echo "$@"
  until "$@"; do
    n=$((n+1))  
    if [ $n -ge $max ]; then
      echo "Comando falló tras $n intentos: $*"
      return 1
    fi
    echo "Intento $n fallido. Reintentando en $delay segundos..."
    sleep $delay
  done
}
export -f exec_until_done

# Metodo para descargar y ejecutar scripts remotos
source_remote_script() {
  REMOTE_SCRIPT=$REMOTE_REPO/$1
  echo "REMOTE_SCRIPT: $REMOTE_SCRIPT"
  exec_until_done curl -sSfL -O $REMOTE_SCRIPT || { echo "Error descargando $REMOTE_SCRIPT"; exit 1; }
  SCRIPT=$(basename $REMOTE_SCRIPT)
  chmod +x $SCRIPT
  chown $USER:$USER $SCRIPT
  source $SCRIPT
}

source_remote_script basics.sh

[[ $server_type == "devops" ]] && source_remote_script devops.sh
