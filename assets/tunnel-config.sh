#!/bin/bash
remote_repo=$1
# Variables para obtener los archivos del repositorio remoto
echo "🔧 > Configurando Ngrok service"
    echo "🌍 > Recuperando script de arranque para Ngrok..."
        remote_ngrok_start_script=$remote_repo/ngrok-start.sh
        ngrok_start_script=$HOME/bin/$(basename $remote_ngrok_start_script)
        temp_file=$(mktemp)
        echo "ngrok_start_script: $ngrok_start_script"
        echo "remote_ngrok_start_script: $remote_ngrok_start_script"
        exec_until_done curl -sSfL -o $temp_file $remote_ngrok_start_script || { echo "Error descargando $remote_ngrok_start_script"; exit 1; }
        envsubst < $temp_file > $ngrok_start_script
        rm -f $temp_file
        chmod +x $ngrok_start_script
        chown $USER:$USER $ngrok_start_script
        echo "🔎📄 >>> BOF: $ngrok_start_script"
        cat $ngrok_start_script
        echo "🔎📄 >>> EOF $ngrok_start_script"

    echo "🌍 > Recuperando servicio systemd para Ngrok..."
        remote_ngrok_start_service=$remote_repo/ngrok-start.service
        ngrok_start_service=$HOME/.config/$(basename $remote_ngrok_start_service)
        temp_file=$(mktemp)
        echo "ngrok_start_service: $ngrok_start_service"
        echo "remote_ngrok_start_service: $remote_ngrok_start_service"
        exec_until_done curl -sSfL -o $temp_file $remote_ngrok_start_service || { echo "Error descargando $remote_ngrok_start_service"; exit 1; }
        envsubst < $temp_file > $ngrok_start_service
        rm -f $temp_file
        sudo ln -s $ngrok_start_service /etc/systemd/system/
        echo "🔎📄 >>> BOF: $ngrok_start_service"
        cat $ngrok_start_service
        echo "🔎📄 >>> EOF: $ngrok_start_service"

    echo "⚙️ > Iniciando el servicio systemd de Ngrok..."
        sudo systemctl stop ngrok-start.service || true 
        sudo systemctl daemon-reload
        sudo systemctl daemon-reexec
        sudo systemctl enable ngrok-start.service
        sudo systemctl start ngrok-start.service
        sudo systemctl status ngrok-start.service
echo "✅ > Servicio de Ngrok listo."

echo "🔧 > Configurando proxy de Ngrok usando Nginx..."
    echo "🌍 > Recuperando configuración para el proxy Nginx..."
        remote_ngrok_proxy_config=$remote_repo/ngrok-proxy.conf
        ngrok_proxy_config=$HOME/.config/$(basename $remote_ngrok_proxy_config)
        temp_file=$(mktemp)
        echo "ngrok_proxy_config: $ngrok_proxy_config"
        echo "remote_ngrok_proxy_config: $remote_ngrok_proxy_config"
        exec_until_done curl -sSfL -o $temp_file $remote_ngrok_proxy_config || { echo "Error descargando $remote_ngrok_proxy_config"; exit 1; }
        envsubst '${PROD_SERVER} ${UAT_SERVER} ${DEVOPS_SERVER}' < $temp_file > $ngrok_proxy_config
        rm -f $temp_file
        echo "🔎📄 >>> BOF: $ngrok_proxy_config"
        cat $ngrok_proxy_config
        echo "🔎📄 >>> EOF: $ngrok_proxy_config"

    echo "⚙️ > Estableciendo disponibilidad y habilitación del servicio de proxy Nginx..."
        sudo rm -f /etc/nginx/sites-available/$(basename $ngrok_proxy_config)
        sudo ln -s $ngrok_proxy_config /etc/nginx/sites-available/
        sudo rm -f /etc/nginx/sites-enabled/$(basename $ngrok_proxy_config)
        sudo ln -s $ngrok_proxy_config /etc/nginx/sites-enabled/
        sudo nginx -t  

    echo "⚙️ > Reiniciando Nginx para aplicar los cambios..."
        sudo systemctl enable nginx
        sudo systemctl start nginx
        sudo systemctl reload nginx
        sudo systemctl status nginx
echo "✅ > Nginx listo."
