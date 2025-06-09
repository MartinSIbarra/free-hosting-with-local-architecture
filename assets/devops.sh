#!/bin/bash
# Valores por defecto
remote_repo="$1"
ngrok_auth_token="$2"
ngrok_tunnel_url="$3"
duckdns_token="$4"
email_for_keys="$5"

echo "🔧 > Agregando variables de entorno para DevOps..." && {
    file_name="devops.env"
    setup_remote_file $file_name $remote_repo .config other 'envsubst-false'

    [[ -n "$ngrok_auth_token" ]] && sed -i "s/XXXngrok-auth-tokenXXX/$ngrok_auth_token/g" $HOME/.config/$file_name
    [[ -n "$ngrok_tunnel_url" ]] && sed -i "s/XXXngrok-tunnel-urlXXX/$ngrok_tunnel_url/g" $HOME/.config/$file_name
    [[ -n "$duckdns_token" ]] && sed -i "s/XXXduckdns-tokenXXX/$duckdns_token/g" $HOME/.config/$file_name
    [[ -n "$email_for_keys" ]] && sed -i "s/XXXemail-for-keysXXX/$email_for_keys/g" $HOME/.config/$file_name

    echo "set -a && source $HOME/.config/$file_name && set +a" >> $HOME/.config/customs.sh
    set -a && source $HOME/.config/$file_name && set +a
} && echo "✅ > Variables de entorno para DevOps agregadas."

execute_remote_script tunnel-install.sh $remote_repo

execute_remote_script tunnel-config.sh $remote_repo

execute_remote_script duckdns-config.sh $remote_repo