#!/bin/bash
validate_arguments() {
    # Procesar argumentos
    for arg in "$@"; do
        case $arg in
        --branch-name=*) repo_branch="${arg#*=}" ;;
        --help)
            echo ""
            echo "  Uso: $0 [--branch-name=<branch/name>]"
            echo ""
            echo "  --branch-name:   Nombre de de la rama que se quiere ejecutar, el parámetro"
            echo "                   está destinado al uso de ramas distintas a main, para"
            echo "                   pruebas de ramas de desarrollo, por ej. para la rama"
            echo "                   feature/nueva se debe usar el parametro de la siguiente"
            echo "                   forma: --branch-name=feature/desa"
            echo ""
            exit 0
            ;;
        *)
            echo "Argumento no reconocido: $arg, use --help para ver la ayuda."
            exit 1
            ;;
        esac
    done
}

show_devops_server_menu() {
    echo -e "\n  Se requieren los siguientes datos para configurar el servidor DevOps:"
    [[ -n "$ngrok_auth_token" ]] && echo "   - Token de Ngrok: $ngrok_auth_token"
    [[ -n "$ngrok_tunnel_url" ]] && echo "   - URL de Ngrok: $ngrok_tunnel_url"
    [[ -n "$duckdns_token" ]] && echo "   - TOKEN de DuckDNS: $duckdns_token"
    [[ -n "$email_for_keys" ]] && echo "   - Email para VPN keys: $email_for_keys"
    [[ -z "$ngrok_auth_token" ]] && read -p "   - Ingresar TOKEN para Ngrok: " ngrok_auth_token
    [[ -z "$ngrok_tunnel_url" ]] && read -p "   - Ingresar URL para Ngrok: " ngrok_tunnel_url
    [[ -z "$duckdns_token" ]] && read -p "   - Ingresar TOKEN para DuckDNS: " duckdns_token
    [[ -z "$email_for_keys" ]] && read -p "   - Ingresar EMAIL para VPN keys: " email_for_keys

    [[ -n "$ngrok_auth_token" ]] && \
    [[ -n "$ngrok_tunnel_url" ]] && \
    [[ -n "$duckdns_token" ]] && \
    [[ -n "$email_for_keys" ]] && {
        devops_data_complete=true
        echo -e "\n  Todos los datos necesarios han sido proporcionados."
    } || {
        echo -e "\n  Faltan datos necesarios para continuar. Por favor, completa todos los campos."
    }
}

show_server_menu() {
    devops_server_label="DevOps Server"
    prod_server_label="Production Server"
    uat_server_label="UAT Server"
    server_complete=false
    devops_data_complete=false

    while [[ "$server_complete" == false ]]; do
        clear
        echo "___________________________________________________________"
        echo ""
        echo " Bienvenido al menú de instalación de servidores virtuales"
        echo " Selecciona una opción para continuar, se generará una "
        echo " máquina virtual con Vagrant y VirtualBox "
        echo "___________________________________________________________"
        echo ""
        case "$server" in
        "" | 0)
            echo "  1) $devops_server_label"
            echo "  2) $prod_server_label"
            echo "  3) $uat_server_label"
            echo -e "\n  0) Salir"
            if [ "$server" == "0" ]; then
                echo -e "\n  Saliendo del instalador..."
                echo ""
                exit 0
            else
                echo -e "\n  Selecciona una opción de 1 a 3 ó 0 para salir."
                read -rsn1 server # Leer una tecla sin Enter
            fi
            ;;
        1 | 2 | 3)
            case "$server" in
            1)
                server_dir="devops-server"
                server_label="$devops_server_label"
                ;;
            2)
                server_dir="prod-server"
                server_label="$prod_server_label"
                ;;
            3)
                server_dir="uat-server"
                server_label="$uat_server_label"
                ;;
            esac
            if [[ -f "$server_dir/Vagrantfile" ]]; then
                echo -e "\n  Ya existe la máquina virtual para esta opcion, no se puede crear."
                echo "  Presiona cualquier tecla para continuar."
                server=""
                read -rsn1
            else
                echo "  Se instalará: $server_label"
                if [ "$server" == "1" ]; then
                    show_devops_server_menu
                    [[ $devops_data_complete == true ]] && server_complete=true
                else
                    server_complete=true
                fi
                if [ $server_complete == true ]; then
                    echo -e "\n  Presiona Enter para confirmar ó ESC para volver al menú inicial."
                else
                    echo -e "\n  Presiona Enter para continuar ó ESC para volver al menú inicial."
                fi
                while true; do
                    read -rsn1 confirm
                    if [[ "$confirm" == "" ]]; then # Enter = confirmar
                        break
                    elif [[ "$confirm" == $'\x1b' ]]; then # ESC = volver
                        server_complete=false
                        server=""
                        ngrok_auth_token=""
                        ngrok_tunnel_url=""
                        duckdns_token=""
                        email_for_keys=""
                        break
                    fi
                done
            fi
            ;;
        *) server="" ;;
        esac
    done
}

execute_command() {
    max_retries=10
    retry_delay=5
    attempt=1
    until eval "$1"; do
        if [ $attempt -gt $max_retries ]; then
            echo "[$(date)] Fallo tras $max_retries intentos. Abortando."
            echo "$attempt"
            exit 1
        fi
        attempt=$((attempt + 1))
        sleep "$retry_delay"
    done
}

repo_branch="main"
validate_arguments "$@"
remote_repo="https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/refs/heads/$repo_branch/assets"

server_dir=""
server_label=""
server=""
ngrok_auth_token=""
ngrok_tunnel_url=""
duckdns_token=""
email_for_keys=""
show_server_menu

mkdir -p "$server_dir"
cd "$server_dir"

# Helper para ejecutar comandos con reintentos, se utiliza para curl por timeout

execute_command "curl -sSOfL $remote_repo/Vagrantfile"
# Se reemplazan las variables con los valores segun el entorno en el Vagrantfile
sed -i "s/repo_branch = \"main\"/repo_branch = \"$repo_branch\"/g" Vagrantfile
sed -i "s/ngrok_auth_token: \"\"/ngrok_auth_token: \"$ngrok_auth_token\"/g" Vagrantfile
sed -i "s/ngrok_tunnel_url: \"\"/ngrok_tunnel_url: \"$ngrok_tunnel_url\"/g" Vagrantfile
sed -i "s/duckdns_token: \"\"/duckdns_token: \"$duckdns_token\"/g" Vagrantfile
sed -i "s/email_for_keys: \"\"/email_for_keys: \"$email_for_keys\"/g" Vagrantfile

echo "  Instalando $server_label..."
echo ""
vagrant up && vagrant reload --provision-with post1,post2,post3 && vagrant reload
