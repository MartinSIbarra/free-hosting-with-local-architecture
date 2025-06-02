#!/bin/bash
remote_repo=$1

echo "🔧 > Actualizando el Package Manager..."
    sudo apt-get update
    sudo apt-get upgrade -y
echo "✅ > Package Manager actualizado."

echo "🔧 > Instalando Paquetes y dependencias..."
    sudo apt-get install -y \
        apt-transport-https ca-certificates gnupg2 software-properties-common locales gettext \
        build-essential dkms linux-headers-amd64 curl busybox git vim wget unzip
echo "✅ > Paquetes y dependencias instalados."

echo "🔧 > Agregado carpetas de configuraciones, logs y ejecutables..."
    mkdir -p $HOME/.config
    rm -f $HOME/.config/customs.sh && touch $HOME/.config/customs.sh
    chmod +x $HOME/.config/customs.sh
    chown $USER:$USER $HOME/.config/customs.sh
    echo "source $HOME/.config/customs.sh" >> $HOME/.bashrc

    mkdir -p $HOME/logs
    
    mkdir -p $HOME/bin
    echo "export PATH=$HOME/bin:\$PATH" >> $HOME/.config/customs.sh    
echo "✅ > Carpetas de configuraciones, logs y ejecutables agregadas."

echo "🔧 > Agregando variables de entorno..."
# Variables para obtener los archivos del repositorio remoto
    remote_basics_vars=$remote_repo/basics.env
    basics_vars=$HOME/.config/$(basename $remote_basics_vars)
    echo "basics_vars: $basics_vars"
    echo "remote_basics_vars: $remote_basics_vars"
    exec_until_done curl -sSfL -o $basics_vars $remote_basics_vars || { echo "Error descargando $remote_basics_vars"; exit 1; }
    echo "set -a && source $basics_vars && set +a" >> $HOME/.config/customs.sh
    set -a && source $basics_vars && set +a
echo "✅ > Variables de entorno agregadas."

echo "🔧 > Agregando aliases customs..."
    remote_aliases_script=$remote_repo/aliases.sh
    aliases_script="$HOME/.config/$(basename $remote_aliases_script)"
    echo "aliases_script: $aliases_script"
    echo "remote_aliases_script: $remote_aliases_script"
    exec_until_done curl -sSfL -o $aliases_script $remote_aliases_script || { echo "Error descargando $remote_aliases_script"; exit 1; }
    chmod +x $aliases_script
    chown $USER:$USER $aliases_script
    echo "source $aliases_script" >> $HOME/.config/customs.sh
echo "✅ > Alias customs agregados."

echo "🔧 > Configurando locales es_AR.UTF-8 y lenguaje en_US.UTF-8..."
    # Asegurarse de que esté habilitado en /etc/locale.gen
    if ! grep -q "^es_AR.UTF-8 UTF-8" /etc/locale.gen; then
        echo "es_AR.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
    fi
    sudo locale-gen es_AR.UTF-8 en_US.UTF-8
    sudo update-locale
    remote_locale_vars=$remote_repo/locale.env
    echo "remote_locale_vars: $remote_locale_vars"
    exec_until_done sudo curl -sSfL -o /etc/default/locale $remote_locale_vars || { echo "Error descargando $remote_locale_vars"; exit 1; }
    set -a && source /etc/default/locale && set +a
echo "✅ > Locales configurados correctamente."

echo "🔧 > Configurando zona horaria..."
    sudo timedatectl set-ntp true
    sudo timedatectl set-timezone America/Argentina/Buenos_Aires
echo "✅ > Zona horaria configurada."
