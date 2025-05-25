#!/bin/bash

show_menu=true 
option=""
server_path=""
server_label=""
devops_server_label="DevOps Server"
prod_server_label="Production Server"
uat_server_label="UAT Server"

while [[ "$show_menu" == true ]]; do
    clear
    echo "___________________________________________________________"
    echo ""
    echo " Bienvenido al menú de instalación de servidores virtuales"
    echo " Selecciona una opción para continuar, se generará una "
    echo " máquina virtual con Vagrant y VirtualBox "
    echo "___________________________________________________________"
    echo ""
    echo "  1) $devops_server_label"
    echo "  2) $prod_server_label"
    echo "  3) $uat_server_label"
    echo ""
    echo "  0) Salir"
    echo ""
    echo "  Selecciona una opción (1-3) o 0 para salir:"

    read -rsn1 input  # Leer una tecla sin Enter

    case "$input" in
        0)
            echo -e "\n  Saliendo..."
            echo ""
            exit 0
            ;;
        1|2|3)
            case "$input" in
                1) 
                    server_path="devops-server" 
                    server_label="$devops_server_label"
                    ;;
                2) 
                    server_path="prod-server" 
                    server_label="$prod_server_label"
                    ;;
                3) 
                    server_path="uat-server" 
                    server_label="$uat_server_label"
                    ;;
            esac

            echo -e "\n  Has elegido la opción $input - $server_label"

            if [[ -f "$server_path/Vagrantfile
            " ]]; then
                echo "  Ya existe la máquina virtual para esta option, no se puede crear."
                echo "  Presiona cualquier tecla para volver al menú."
                read -rsn1
            else
                echo "  Presiona Enter para confirmar ó ESC para volver al menú."

                while true; do
                    read -rsn1 confirm
                    if [[ "$confirm" == "" ]]; then  # Enter = confirmar
                        option="$input"
                        show_menu=false
                        break
                    elif [[ "$confirm" == $'\x1b' ]]; then  # ESC = volver
                        break
                    fi
                done
            fi
            ;;
    esac
done

# Helper para ejecutar comandos con reintentos, se utiliza para curl por timeout
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

mkdir -p "$server_path"
cd "$server_path" 
ngrok_config_file="ngrok.conf"
if [[ $option == "1" ]]; then
    if [ ! -f "$ngrok_config_file" ]; then
        echo "AUTH_TOKEN=<su_token_de_ngrok>" > "$ngrok_config_file"
        echo "TUNNEL_URL=<su_url_de_ngrok>" >> "$ngrok_config_file"
        echo ""
        echo "  Se creó el archivo de configuración de ngrok: $server_path/$ngrok_config_file"
        echo "  Editá el archivo y agregá tu token de ngrok y la URL del túnel."
        echo "  Luego debes volver a ejecutar este script."
        echo "  Tené en cuenta que si se realiza la instalacion del servidor de DevOps"
        echo "  sin agregar el token y URL el sevidor de DevOps no funcionará correctamente."
        echo -e "\n  Presione cualquier tecla para continuar..."
        read -rsn1
        echo ""
        exit 0
    fi
fi

execute_command "curl -sSOfL https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/refs/heads/main/assets/Vagrantfile"
echo "  Instalando $server_label..."
echo ""
vagrant up && vagrant reload --provision-with post1,post2,post3