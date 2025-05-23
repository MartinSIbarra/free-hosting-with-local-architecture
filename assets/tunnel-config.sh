#!/bin/bash
# Variables para obtener los archivos del repositorio remoto
echo "🔧 > Configurando Ngrok service"
    echo "🌍 > Recuperando script de arranque para Ngrok..."
        REMOTE_NGROK_START_SCRIPT=$REMOTE_REPO/ngrok-start.sh
        NGROK_START_SCRIPT=$HOME/bin/$(basename $REMOTE_NGROK_START_SCRIPT)
        TEMP_FILE=$(mktemp)
        echo "NGROK_START_SCRIPT: $NGROK_START_SCRIPT"
        echo "REMOTE_NGROK_START_SCRIPT: $REMOTE_NGROK_START_SCRIPT"
        exec_until_done curl -sSfL -o $TEMP_FILE $REMOTE_NGROK_START_SCRIPT || { echo "Error descargando $REMOTE_NGROK_START_SCRIPT"; exit 1; }
        envsubst < $TEMP_FILE > $NGROK_START_SCRIPT
        rm -f $TEMP_FILE
        chmod +x $NGROK_START_SCRIPT
        chown $USER:$USER $NGROK_START_SCRIPT
        echo "🔎📄 >>> BOF: $NGROK_START_SCRIPT"
        cat $NGROK_START_SCRIPT
        echo "🔎📄 >>> EOF $NGROK_START_SCRIPT"

    echo "🌍 > Recuperando servicio systemd para Ngrok..."
        REMOTE_NGROK_START_SERVICE=$REMOTE_REPO/ngrok-start.service
        NEGROK_START_SERVICE=$HOME/.config/$(basename $REMOTE_NGROK_START_SERVICE)
        TEMP_FILE=$(mktemp)
        echo "NEGROK_START_SERVICE: $NEGROK_START_SERVICE"
        echo "REMOTE_NGROK_START_SERVICE: $REMOTE_NGROK_START_SERVICE"
        exec_until_done curl -sSfL -o $TEMP_FILE $REMOTE_NGROK_START_SERVICE || { echo "Error descargando $REMOTE_NGROK_START_SERVICE"; exit 1; }
        envsubst < $TEMP_FILE > $NEGROK_START_SERVICE
        rm -f $TEMP_FILE
        sudo ln -s $NEGROK_START_SERVICE /etc/systemd/system/
        echo "🔎📄 >>> BOF: $NEGROK_START_SERVICE"
        cat $NEGROK_START_SERVICE
        echo "🔎📄 >>> EOF: $NEGROK_START_SERVICE"

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
        REMOTE_NGROK_PROXY_CONFIG=$REMOTE_REPO/ngrok-proxy.conf
        NGROK_PROXY_CONFIG=$HOME/.config/$(basename $REMOTE_NGROK_PROXY_CONFIG)
        TEMP_FILE=$(mktemp)
        echo "NGROK_PROXY_CONFIG: $NGROK_PROXY_CONFIG"
        echo "REMOTE_NGROK_PROXY_CONFIG: $REMOTE_NGROK_PROXY_CONFIG"
        exec_until_done curl -sSfL -o $TEMP_FILE $REMOTE_NGROK_PROXY_CONFIG || { echo "Error descargando $REMOTE_NGROK_PROXY_CONFIG"; exit 1; }
        envsubst '${PROD_SERVER} ${UAT_SERVER} ${DEVOPS_SERVER}' < $TEMP_FILE > $NGROK_PROXY_CONFIG
        rm -f $TEMP_FILE
        echo "🔎📄 >>> BOF: $NGROK_PROXY_CONFIG"
        cat $NGROK_PROXY_CONFIG
        echo "🔎📄 >>> EOF: $NGROK_PROXY_CONFIG"

    echo "⚙️ > Estableciendo disponibilidad y habilitación del servicio de proxy Nginx..."
        sudo rm -f /etc/nginx/sites-available/$(basename $NGROK_PROXY_CONFIG)
        sudo ln -s $NGROK_PROXY_CONFIG /etc/nginx/sites-available/
        sudo rm -f /etc/nginx/sites-enabled/$(basename $NGROK_PROXY_CONFIG)
        sudo ln -s $NGROK_PROXY_CONFIG /etc/nginx/sites-enabled/
        sudo nginx -t  

    echo "⚙️ > Reiniciando Nginx para aplicar los cambios..."
        sudo systemctl enable nginx
        sudo systemctl start nginx
        sudo systemctl reload nginx
        sudo systemctl status nginx
echo "✅ > Nginx listo."
