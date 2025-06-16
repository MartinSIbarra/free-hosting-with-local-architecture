#!/bin/bash
remote_repo="$1"
duckdns_domain="$2"
devops_server_email="$3"
devops_server_email_app_token=$(echo "$4" | tr '-' ' ')
email_for_keys="$5"
encryption_key="$6"
vpn_pwd="$7"

server_lan_ip="$(hostname -I | awk '{print $2}')"
server_remote_url="http://$duckdns_domain.duckdns.org"

temp_path="$HOME/temp-vpn-setup"

echo "🔧 > Instalando paquetes para configuración de VPN..." && {
    sudo apt update
    # Seteando variables de configuración para los paquetes para evitar prompts
    echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | sudo debconf-set-selections
    echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | sudo debconf-set-selections
    echo "postfix postfix/mailname string localhost" | sudo debconf-set-selections
    echo "postfix postfix/main_mailer_type string Internet Site" | sudo debconf-set-selections
    # Instalando utilitarios para vpn y correo
    sudo apt install -y wireguard postfix mutt libsasl2-2 libsasl2-modules p7zip-full iptables-persistent
} && echo "✅ > Instalación de paquetes completada."

echo "🔧 > Configurando VPN y Generando archivos de configuracion para peers..." && {
    #-------------------------------------------------------------------------------------------------------------------------------------------------
    # Methods
    #-------------------------------------------------------------------------------------------------------------------------------------------------
    create_server_config_file() {
        local server_keys_path="$1"
        local client_keys_path="$2"

        local path="/etc/wireguard/server.conf" # Path del archivo de configuración del servidor

        sudo rm -f $path
        echo "[Interface]" | sudo tee $path >/dev/null
        echo "PrivateKey = $(cat $server_keys_path/server-privatekey)" | sudo tee -a $path >/dev/null
        echo "Address = 10.0.0.1/24, fd42:42:42::1/64" | sudo tee -a $path >/dev/null
        echo "ListenPort = 51820" | sudo tee -a $path >/dev/null
        echo "SaveConfig = true" | sudo tee -a $path >/dev/null
        echo "PostUp = iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE" | sudo tee -a $path >/dev/null
        echo "PostDown = iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE" | sudo tee -a $path >/dev/null
        echo "" | sudo tee -a $path >/dev/null
        for i in {10..29}; do
            echo "[Peer]" | sudo tee -a $path >/dev/null
            echo "PublicKey = $(cat $client_keys_path/client$i-publickey)" | sudo tee -a $path >/dev/null
            echo "AllowedIPs = 10.0.0.$i/32" | sudo tee -a $path >/dev/null
        done
    }

    create_clients_install_file() {
        local client_id=$1
        local server_address=$2
        local server_keys_path="$3"
        local client_keys_path="$4"
        local path="$5/vpn-client$client_id-install.sh" # Path para los instaladores de los clientes
        local vpn_pwd="$6"

        echo '#!/bin/bash' | tee "$path" >/dev/null
        echo '# Objetivo:' | tee -a "$path" >/dev/null
        echo '#   Este script esta destinado a la instalción y configuración del cliente de VPN con wireguard' | tee -a "$path" >/dev/null
        echo '#   para la red OWFEMA.' | tee -a "$path" >/dev/null
        echo '#    - Genera el archivo de configuración del cliente en /etc/wireguard/client.conf' | tee -a "$path" >/dev/null
        echo '#    - Genera el ejecutable de configuración del cliente en /usr/local/bin/vpn-client' | tee -a "$path" >/dev/null
        echo '' | tee -a "$path" >/dev/null
        echo '# Instrucciones:' | tee -a "$path" >/dev/null
        echo '#    - Guarde el contenido en un archivo de su sistema de archivos.' | tee -a "$path" >/dev/null
        echo '#    - Agrege los permisos de ejecución al script --> sudo chmod +x [nombre_archivo]' | tee -a "$path" >/dev/null
        echo '#    - Ejecute --> ./[nombre_archivo]' | tee -a "$path" >/dev/null
        echo '' | tee -a "$path" >/dev/null
        echo 'sudo wg-quick down client > /dev/null 2>&1 || true' | tee -a "$path" >/dev/null
        echo 'sudo apt update > /dev/null 2>&1 && sudo apt install wireguard resolvconf -y > /dev/null 2>&1' | tee -a "$path" >/dev/null
        echo '' | tee -a "$path" >/dev/null
        echo 'config_file_path="/etc/wireguard/client.conf"' | tee -a "$path" >/dev/null
        echo 'config_file="[Interface]' | tee -a "$path" >/dev/null
        echo "PrivateKey = $(cat $client_keys_path/client$client_id-privatekey)" | tee -a "$path" >/dev/null
        echo "Address = 10.0.0.$client_id/24, fd42:42:42::$client_id/128" | tee -a "$path" >/dev/null
        echo 'DNS = 1.1.1.1' | tee -a "$path" >/dev/null
        echo 'SaveConfig = true' | tee -a "$path" >/dev/null
        echo '' | tee -a "$path" >/dev/null
        echo '[Peer]' | tee -a "$path" >/dev/null
        echo "PublicKey = $(cat $server_keys_path/server-publickey)" | tee -a "$path" >/dev/null
        echo "Endpoint = $server_address:51820" | tee -a "$path" >/dev/null
        echo 'AllowedIPs = 0.0.0.0/0, ::/0' | tee -a "$path" >/dev/null
        echo 'PersistentKeepalive = 25' | tee -a "$path" >/dev/null
        echo '"' | tee -a "$path" >/dev/null
        echo 'sudo rm -f "$config_file_path"' | tee -a "$path" >/dev/null
        echo 'echo "$config_file" | sudo tee "$config_file_path" >/dev/null' | tee -a "$path" >/dev/null
        echo '' | tee -a "$path" >/dev/null
        echo 'bin_file_path="/usr/local/bin/vpn-client"' | tee -a "$path" >/dev/null
        echo "bin_file='" | tee -a "$path" >/dev/null
        echo '    if [ "$1" != "up" ] && [ "$1" != "down" ]; then' | tee -a "$path" >/dev/null
        echo '        echo "\"$(basename $0) up\" para iniciar la conexión a la vpn, ó \"$(basename $0) down\" para detenerla."' | tee -a "$path" >/dev/null
        echo '        exit 1' | tee -a "$path" >/dev/null
        echo '    fi' | tee -a "$path" >/dev/null
        echo '    sudo wg-quick "$1" client' | tee -a "$path" >/dev/null
        echo "'" | tee -a "$path" >/dev/null
        echo "sudo rm -f \$bin_file_path" | tee -a "$path" >/dev/null
        echo 'echo "$bin_file" | sudo tee "$bin_file_path" >/dev/null && sudo chmod +x "$bin_file_path"' | tee -a "$path" >/dev/null
        echo '' | tee -a "$path" >/dev/null
        echo 'if [ -d /vagrant ] || id vagrant &>/dev/null; then' | tee -a "$path" >/dev/null
        echo '    # Agregando configuración para permitir autenticación por contraseña solo desde la VPN' | tee -a "$path" >/dev/null
        echo '    echo "# Solo permitir autenticación por contraseña desde la VPN" | sudo tee -a /etc/ssh/sshd_config >/dev/null' | tee -a "$path" >/dev/null
        echo '    echo "Match Address 10.0.0.0/24,192.168.0.0/24" | sudo tee -a /etc/ssh/sshd_config >/dev/null' | tee -a "$path" >/dev/null
        echo '    echo "    PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config >/dev/null' | tee -a "$path" >/dev/null
        echo '    echo "# En todos los demás casos, desactivar" | sudo tee -a /etc/ssh/sshd_config >/dev/null' | tee -a "$path" >/dev/null
        echo '    echo "Match all" | sudo tee -a /etc/ssh/sshd_config >/dev/null' | tee -a "$path" >/dev/null
        echo '    echo "    PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config >/dev/null' | tee -a "$path" >/dev/null
        echo '    echo "# Asegurarse de que PubkeyAuthentication esté activo para no romper vagrant ssh" | sudo tee -a /etc/ssh/sshd_config >/dev/null' | tee -a "$path" >/dev/null
        echo '    echo "PubkeyAuthentication yes" | sudo tee -a /etc/ssh/sshd_config >/dev/null' | tee -a "$path" >/dev/null
        echo '    # Generando password para el usuario vagrant' | tee -a "$path" >/dev/null
        echo "    echo \"vagrant:$vpn_pwd\" | sudo chpasswd" | tee -a "$path" >/dev/null
        echo '    sudo systemctl restart ssh' | tee -a "$path" >/dev/null
        echo 'fi' | tee -a "$path" >/dev/null
        echo '' | tee -a "$path" >/dev/null
        echo 'echo "Cliente para la VPN instalado."' | tee -a "$path" >/dev/null
        echo 'echo ""' | tee -a "$path" >/dev/null
        echo 'echo "Usa \"vpn-client up\" para iniciar la conexión de vpn, ó \"vpn-client down\" para detenerla."' | tee -a "$path" >/dev/null
        echo 'echo ""' | tee -a "$path" >/dev/null
    }

    #-------------------------------------------------------------------------------------------------------------------------------------------------
    # Main
    #-------------------------------------------------------------------------------------------------------------------------------------------------
    rm -rf "$temp_path"
    mkdir "$temp_path"

    # Creando pares de claves privadas y públicas para el servidor
    wg genkey | tee "$temp_path/server-privatekey" | wg pubkey >"$temp_path/server-publickey"

    client_keys_path="$temp_path/client-keys"
    rm -rf "$client_keys_path"
    mkdir "$client_keys_path"

    client_installers_path="$temp_path/client-installers"
    rm -rf "$client_installers_path"
    mkdir "$client_installers_path"

    for i in {10..19}; do
        # Creando pares de claves privadas y públicas para los clientes de la LAN
        wg genkey | tee "$client_keys_path/client$i-privatekey" | wg pubkey >"$client_keys_path/client$i-publickey"
        # Creando archivo de instalación de vpn para los clientes de la LAN
        create_clients_install_file $i "$server_lan_ip" "$temp_path" "$client_keys_path" "$client_installers_path" "$vpn_pwd"
    done

    for i in {20..29}; do
        # Creando pares de claves privadas y públicas para los clientes de la WAN
        wg genkey | tee "$client_keys_path/client$i-privatekey" | wg pubkey >"$client_keys_path/client$i-publickey"
        # Creando archivo de instalación de vpn para los clientes de la WAN
        create_clients_install_file $i "$server_remote_url" "$temp_path" "$client_keys_path" "$client_installers_path" "$vpn_pwd"
    done

    # Creando archivo configuracion de vpn para el servidor
    create_server_config_file "$temp_path" "$client_keys_path"

    # Creando archivo bin para facilitar el uso
    bin_file_path="/usr/local/bin/vpn-server"
    bin_file='
        if [ "$1" != "up" ] && [ "$1" != "down" ]; then
            echo "Uso: \"$(basename "$0") up\" para iniciar el servidor de vpn, ó \"$(basename "$0") down\" para detenerlo."
            exit 1
        fi
        sudo wg-quick "$1" server
    '
    sudo rm -f $bin_file_path
    echo "$bin_file" | sudo tee $bin_file_path >/dev/null && sudo chmod +x $bin_file_path

    echo ""
    echo "Usa \"$(basename "$bin_file_path") up\" para iniciar el servidor de vpn, ó \"$(basename "$bin_file_path") down\" para detenerlo."
    echo ""

} && echo "✅ > Configuración de VPN completada y archivos de configuracion para peers creados."

echo "🔧 > Configurando acceso a internet para peers desde la VPN..." && {
    # Configurando wireguard para permitir el uso de internet en la VPN
    wg_interface="server"
    wg_subnet="10.0.0.0/24"
    out_iface="$(ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++){if($i=="dev"){print $(i+1);exit}}}')"

    # Habilitando reenvío IP...
    grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -w net.ipv4.ip_forward=1
    # Habilitando reenvío IPv6...
    sudo sed -i '/^#* *net.ipv6.conf.all.forwarding/d' /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding = 1" | sudo tee -a /etc/sysctl.conf >/dev/null
    sudo sysctl -p

    # Agregando regla NAT para salida a Internet (MASQUERADE)...
    sudo iptables -t nat -A POSTROUTING -s $wg_subnet -o $out_iface -j MASQUERADE

    # Configurando NAT66 con nftables...
    # Crear tabla ip6 nat si no existe
    sudo nft list table ip6 nat &>/dev/null || sudo nft add table ip6 nat
    # Crear chain POSTROUTING si no existe
    if ! sudo nft list chain ip6 nat POSTROUTING &>/dev/null; then
        sudo nft add chain ip6 nat POSTROUTING '{ type nat hook postrouting priority 100 ; }'
    fi
    # Agregar regla masquerade (evita duplicados)
    if ! sudo nft list chain ip6 nat POSTROUTING | grep -q "oifname \"$out_iface\" masquerade"; then
        sudo nft add rule ip6 nat POSTROUTING oifname "$out_iface" masquerade
    fi
    # Guardando reglas para que persistan...
    sudo nft list ruleset | sudo tee /etc/nftables.conf >/dev/null

    # Guardando reglas de iptables...
    sudo netfilter-persistent save

    sudo systemctl enable nftables
    sudo systemctl restart nftables

    # Habilitando servicio de WireGuard en el arranque...
    sudo systemctl enable wg-quick@$wg_interface
    sudo systemctl restart wg-quick@$wg_interface
} && echo "✅ > Configuración de acceso a internet para peers desde la VPN completada."

echo "🔧 > Configurando Postfix para envío de correos con gmail..." && {
    # Creando archivo de configuración de Postfix para enviar correos
    append_to_main_cf="
relayhost = [smtp.gmail.com]:587

smtp_use_tls = yes
smtp_tls_security_level = encrypt
smtp_tls_note_starttls_offer = yes

smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous
smtp_sasl_mechanism_filter = plain
"
    echo "$append_to_main_cf" | sudo tee -a /etc/postfix/main.cf >/dev/null

    # Creando archivo de contraseñas para Postfix
    echo "[smtp.gmail.com]:587 $devops_server_email:$devops_server_email_app_token" | sudo tee /etc/postfix/sasl_passwd >/dev/null

    sudo chmod 600 /etc/postfix/sasl_passwd
    sudo postmap /etc/postfix/sasl_passwd >/dev/null 2>&1
    sudo systemctl restart postfix >/dev/null 2>&1
} && echo "✅ > Configuración de Postfix para envío de correos con gmail completada."

echo "🔧 > Enviando archivos de instalacion para peers..." && {
    # Enviando correo con los archivos de instalación de los clientes
    attachment_path="$temp_path/attachment"

    mkdir -p "$attachment_path"

    rm -rf "$attachment_path/vpn*"
    7z a -r -p"$encryption_key" -mhe "$attachment_path/vpn.7z" "$client_installers_path/" >/dev/null 2>&1
    base64 -w 0 "$attachment_path/vpn.7z" >"$attachment_path/vpn.bin"

    email_subject="OWFEMA DevOps VPN"
    email_body="Este es un correo con el archivo de instalacion para clientes de la VPN adjunto en base64.
    para utilizarlo debe descargar el archivo adjunto, desencriptarlo de base64 y descomprimirlo.
    - Para desencriptar de base64: base64 -d vpn.bin > vpn.7z
    - Para descomprimir: 7z x vpn.7z -p\"[encryption_key]\" -o\"[path]\""
    email_destinatary="$email_for_keys"

    echo "$email_body" | mutt -s "$email_subject" -a "$attachment_path/vpn.bin" -- $email_destinatary >/dev/null 2>&1

    rm -rf "$temp_path"
} && echo "✅ > Envío de archivos de instalación para peers completado."

echo "🔧 > Configurando ssh para acceso con password desde la VPN..." && {
    # Agregando configuración para permitir autenticación por contraseña solo desde la VPN
    echo "# Solo permitir autenticación por contraseña desde la VPN" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "Match Address 10.0.0.0/24,192.168.0.0/24" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "    PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "# En todos los demás casos, desactivar" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "Match all" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "    PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "# Asegurarse de que PubkeyAuthentication esté activo para no romper vagrant ssh" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "PubkeyAuthentication yes" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    # Generando password para el usuario vagrant
    echo "vagrant:$vpn_pwd" | sudo chpasswd
} && echo "✅ > Configuración de ssh completada."
