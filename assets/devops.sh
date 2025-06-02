#!/bin/bash
# Valores por defecto
remote_repo="$1"
ngrok_auth_token="$2"
ngrok_tunnel_url="$3"

echo "🔧 > Agregando variables de entorno para DevOps..."
    remote_devops_env=$remote_repo/devops.env
    devops_env=$HOME/.config/$(basename $remote_devops_env)
    echo "devops_env: $devops_env"
    echo "remote_devops_env: $remote_devops_env"
    exec_until_done curl -sSfL -o $devops_env $remote_devops_env || { echo "Error descargando $remote_devops_env"; exit 1; }
    
    [[ -n "$ngrok_auth_token" ]] && sed -i "s/XXXngrok-auth-tokenXXX/$ngrok_auth_token/g" $devops_env
    [[ -n "$ngrok_tunnel_url" ]] && sed -i "s/XXXngrok-tunnel-urlXXX/$ngrok_tunnel_url/g" $devops_env
    
    echo "set -a && source $devops_env && set +a" >> $HOME/.config/customs.sh
    set -a && source $devops_env && set +a
echo "✅ > Variables de entorno para DevOps agregadas."

source_remote_script tunnel-install.sh

source_remote_script tunnel-config.sh $remote_repo
