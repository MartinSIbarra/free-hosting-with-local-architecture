#!/bin/bash
remote_repo=$1
# Variables para obtener los archivos del repositorio remoto
echo "🔧 > Configurando Ngrok service" && {
    echo "🌍 > Recuperando script de arranque para Ngrok..."
    setup_remote_file ngrok-start.sh $remote_repo bin exec 'envsubst-true'

    echo "🌍 > Recuperando servicio systemd para Ngrok..."
    setup_remote_file ngrok-start.service $remote_repo .config service 'envsubst-true'

    echo "⚙️ > Iniciando el servicio systemd de Ngrok..." && {
        sudo systemctl stop ngrok-start.service || true
        sudo systemctl daemon-reload
        sudo systemctl daemon-reexec
        sudo systemctl enable ngrok-start.service
        sudo systemctl start ngrok-start.service
        sudo systemctl status ngrok-start.service
    }
} && echo "✅ > Servicio de Ngrok listo."

echo "🔧 > Configurando proxy de Ngrok usando Nginx..." && {
    echo "🌍 > Recuperando configuración para el proxy Nginx..."
    ngrok_proxy_conf_commands() {
        envsubst "\'\${PROD_SERVER} \${UAT_SERVER} \${DEVOPS_SERVER}\'" <'$temp_file' >'$file'
        echo "⚙️ > Estableciendo disponibilidad y habilitación del servicio de proxy Nginx..."
        sudo rm -f '/etc/nginx/sites-available/$(basename $file)'
        sudo ln -s '$file /etc/nginx/sites-available/'
        sudo rm -f '/etc/nginx/sites-enabled/$(basename $file)'
        sudo ln -s '$file /etc/nginx/sites-enabled/'
    }
    local file_name="ngrok-proxy.conf"
    setup_remote_file $file_name $remote_repo .config other 'envsubst-false' ngrok_proxy_conf_commands
    sudo nginx -t

    echo "⚙️ > Reiniciando Nginx para aplicar los cambios..."
    sudo systemctl enable nginx
    sudo systemctl start nginx
    sudo systemctl reload nginx
    sudo systemctl status nginx

} && echo "✅ > Proxy Nginx para Ngrok listo."
