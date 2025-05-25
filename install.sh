#!/bin/bash

show_menu=true 
opcion=""
server_folder=""
server_label=""

while [[ "$show_menu" == true ]]; do
    devops_server_label="DevOps Server"
    prod_server_label="Production Server"
    uat_server_label="UAT Server"
    clear
    echo "___________________________________________________________"
    echo ""
    echo " Bienvenido al menú de instalación de servidores virtuales "
    echo " Seleccione una opción para continuar, se generará una "
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
                    server_folder="devops-server" 
                    server_label="$devops_server_label"
                    ;;
                2) 
                    server_folder="prod-server" 
                    server_label="$prod_server_label"
                    ;;
                3) 
                    server_folder="uat-server" 
                    server_label="$uat_server_label"
                    ;;
            esac

            echo -e "\n  Has elegido la opción $input - $server_label"

            if [[ -d "$server_folder" ]]; then
                echo "  Ya existe la máquina virtual para esta opcion, no se puede crear."
                echo "  Presiona cualquier tecla para volver al menú."
                read -rsn1 confirm
            else
                echo "  Presiona Enter para confirmar ó ESC para volver al menú."

                while true; do
                    read -rsn1 confirm
                    if [[ "$confirm" == "" ]]; then  # Enter = confirmar
                        opcion="$input"
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

# Acción tras confirmar
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

echo "  Instalando $server_label..."
echo ""
execute_command "curl -sSOfL https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/refs/heads/main/assets/Vagrantfile"
mkdir $server_folder
cd $server_folder 
vagrant up && vagrant reload --provision-with post1,post2,post3