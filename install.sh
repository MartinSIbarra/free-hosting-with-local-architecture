#!/bin/bash

show_menu=true 
option=""
server_path=""
server_label=""
devops_server_label="DevOps Server"
prod_server_label="Production Server"
uat_server_label="UAT Server"
input=""
repo_branch="main"

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
remote_repo="https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/refs/heads/$repo_branch/assets"

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
    case "$input" in
        1|2|3) ;;
        *)
            echo -e "\n  0) Salir"
            echo -e "\n  Selecciona una opción (1-3) o 0 para salir:"
    esac

    read -rsn1 input  # Leer una tecla sin Enter

    case "$input" in
        0)
            echo -e "\n  Saliendo... \n"
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

            if [[ -f "$server_path/Vagrantfile" ]]; then
                echo -e "\n  Ya existe la máquina virtual para esta opcion, no se puede crear."
                echo "  Presiona cualquier tecla para volver al menú."
                read -rsn1
            else
                if [ $input == 1 ]; then
                    ngrok_auth_token=""
                    ngrok_tunnel_url=""
                    read -p "  - Ingresar token para ngrok: " ngrok_auth_token
                    [ -n "$ngrok_auth_token" ] && read -p "  - Ingresar url para ngrok: " ngrok_tunnel_url
                    [ -z "$ngrok_tunnel_url" ] && input=""
                fi
                if [ -n "$input" ]; then
                    echo -e "\n  Presiona Enter para confirmar ó ESC para volver al menú."

                    while true; do
                        read -rsn1 confirm
                        if [[ "$confirm" == "" ]]; then  # Enter = confirmar
                            option="$input"
                            show_menu=false
                            break
                        elif [[ "$confirm" == $'\x1b' ]]; then  # ESC = volver
                            input=""
                            break
                        fi
                    done
                fi
            fi
            ;;
    esac
done

mkdir -p "$server_path"
cd "$server_path" 

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

execute_command "curl -sSOfL $remote_repo/Vagrantfile"
# Se reemplazan las variables con los valores segun el entorno en el Vagrantfile
sed -i "s/repo_branch = \"main\"/repo_branch = \"$repo_branch\"/g" Vagrantfile
sed -i "s/ngrok_auth_token: \"\"/ngrok_auth_token: \"$ngrok_auth_token\"/g" Vagrantfile
sed -i "s/ngrok_tunnel_url: \"\"/ngrok_tunnel_url: \"$ngrok_tunnel_url\"/g" Vagrantfile

echo "  Instalando $server_label..."
echo ""
vagrant up && vagrant reload --provision-with post1,post2,post3
