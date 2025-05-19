#!/bin/bash
echo "🔧 > Instalando Ngrok y Nginx..."
    exec_until_done curl -sSfL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null 
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list 
    sudo apt-get update 
    sudo apt-get install -y ngrok nginx
echo "✅ > Ngrok y Nginx instalados."
