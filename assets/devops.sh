#!/bin/bash
# Valores por defecto
remote_repo="$1"
ngrok_auth_token="$2"
ngrok_tunnel_url="$3"
duckdns_token="$4"
email_for_keys="$5"

echo "🔧 > Agregando variables de entorno para DevOps..." && {
    local file="devops.env"
    setup_remote_file $file $remote_repo .config other 'envsubst-false'

    [[ -n "$ngrok_auth_token" ]] && sed -i "s/XXXngrok-auth-tokenXXX/$ngrok_auth_token/g" $HOME/.config/$file
    [[ -n "$ngrok_tunnel_url" ]] && sed -i "s/XXXngrok-tunnel-urlXXX/$ngrok_tunnel_url/g" $HOME/.config/$file
    [[ -n "$duckdns_token" ]] && sed -i "s/XXXduckdns-tokenXXX/$duckdns_token/g" $HOME/.config/$file
    [[ -n "$email_for_keys" ]] && sed -i "s/XXXemail-for-keysXXX/$email_for_keys/g" $HOME/.config/$file

    echo "set -a && source $HOME/.config/$file && set +a" >> $HOME/.config/customs.sh
    set -a && source $HOME/.config/$file && set +a
} && echo "✅ > Variables de entorno para DevOps agregadas."

execute_remote_script tunnel-install.sh $remote_repo

execute_remote_script tunnel-config.sh $remote_repo

execute_remote_script duckdns-install.sh $remote_repo