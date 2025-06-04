#!/bin/bash
# Valores por defecto
server_type=""
ngrok_auth_token=""
ngrok_tunnel_url=""
repo_branch="main"

# Procesar argumentos
for arg in "$@"; do
  case $arg in
    --server-type=*) server_type="${arg#*=}" ;;
    --ngrok-auth-token=*) ngrok_auth_token="${arg#*=}" ;;
    --ngrok-tunnel-url=*) ngrok_tunnel_url="${arg#*=}" ;;
    --branch-name=*) repo_branch="${arg#*=}" ;;
    --help)
      echo ""
      echo "  Uso: $0 --server-type=<tipo> [--ngrok-auth-token=<token>] [--ngrok-tunnel-url=<url>] [--branch-name=<branch/name>]"
      echo ""
      echo "  --server-type:        Tipos de servidor permitidos: devops, prod, uat"
      echo ""
      echo "  --ngrok-auth-token:   Token de autenticación para ngrok (obligatorio para --server-type=devops)"
      echo ""
      echo "  --ngrok-tunnel-url:   URL del túnel ngrok (obligatorio para --server-type=devops)"
      echo ""
      echo "  --branch-name:        Nombre de de la rama que se quiere ejecutar, el parámetro"
      echo "                        está destinado al uso de ramas distintas a main, para"  
      echo "                        pruebas de ramas de desarrollo, por ej. para la rama"
      echo "                        feature/nueva se debe usar el parámetro de la siguiente"
      echo "                        forma: --branch-name=feature/desa"
      exit 0
      ;;
    *)
      echo "Argumento no reconocido: $arg, use --help para ver la ayuda."
      exit 1
      ;;
  esac
done
remote_repo="https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/refs/heads/$repo_branch/assets"

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
execute_remote_script() {
  echo "----------------------------------------------------------------------------------------------------------------"
  echo " Metodo: execute_remote_script"
  script=$1
  shift
  remote_script=$remote_repo/$script
  echo "remote_script: $remote_script"
  exec_until_done curl -sSfL -O $remote_script || { echo "Error descargando $remote_script"; exit 1; }
  chmod +x $script
  chown $USER:$USER $script
  echo " --> Ejecutando: $script $@"
  ./$script $@
  echo " --> Borrando: $script"
  rm $script
  echo "----------------------------------------------------------------------------------------------------------------"
}
export -f execute_remote_script

execute_remote_script basics.sh $remote_repo

[[ $server_type == "devops" ]] && execute_remote_script devops.sh $remote_repo $ngrok_auth_token $ngrok_tunnel_url
