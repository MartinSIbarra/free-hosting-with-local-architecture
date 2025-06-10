#!/bin/bash
# This script installs the necessary items for DuckDNS service.
remote_repo=$1

echo "🔧 > Instalando servicio para DuckDNS" && {
    echo "🌍 > Recuperando script para actualizar DuckDNS..." && {
        setup_remote_file duckdns.sh $remote_repo bin exec 'envsubst-true'
    }

    echo "🌍 > Recuperando servicio systemd para DuckDNS..." && {
        duckdns_service_commands='
            sed -i "\${HOME}/$HOME/g" $file
        '
        setup_remote_file duckdns.service $remote_repo .config service 'envsubst-false' "$duckdns_service_commands"
    }

    echo "🌍 > Recuperando timer para servicio systemd de DuckDNS..." && {
        setup_remote_file duckdns.timer $remote_repo .config service 'envsubst-false'
    }

    echo "⚙️ > Iniciando el servicio systemd de DuckDNS con timer..." && {
        sudo systemctl stop duckdns.service || true
        sudo systemctl daemon-reload
        sudo systemctl daemon-reexec
        sudo systemctl enable --now duckdns.timer
        sudo systemctl start duckdns.service
        sudo systemctl status duckdns.service
    } && echo "✅ > Servicio de DuckDNS listo."
} && echo "✅ > Servicio para DuckDNS instalado."
