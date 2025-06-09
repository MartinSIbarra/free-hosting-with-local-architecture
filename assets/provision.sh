#!/bin/bash
# Valores por defecto
server_type=""
ngrok_auth_token=""
ngrok_tunnel_url=""
duckdns_token=""
email_for_keys=""
repo_branch="main"

# Procesar argumentos
for arg in "$@"; do
    case $arg in
    --server-type=*) server_type="${arg#*=}" ;;
    --ngrok-auth-token=*) ngrok_auth_token="${arg#*=}" ;;
    --ngrok-tunnel-url=*) ngrok_tunnel_url="${arg#*=}" ;;
    --duckdns-token=*) duckdns_token="${arg#*=}" ;;
    --email-for-keys=*) email_for_keys="${arg#*=}" ;;
    --branch-name=*) repo_branch="${arg#*=}" ;;
    --help)
        echo ""
        echo "  Uso: $0 --server-type=<tipo> [--ngrok-auth-token=<token>] [--ngrok-tunnel-url=<url>] [--branch-name=<branch/name>]"
        echo ""
        echo "  --server-type:        Tipos de servidor permitidos: devops, prod, uat"
        echo ""
        echo "  --ngrok-auth-token:   Token de autenticación para ngrok (obligatorio para --server-type=devops)"
        echo ""
        echo "  --ngrok-tunnel-url:   URL del túnel ngrok (obligatorio para --server-type=devops)"
        echo ""
        echo "  --duckdns-token:      Token de DuckDNS (obligatorio para --server-type=devops)"
        echo ""
        echo "  --email-for-keys:     Email para las claves de VPN (obligatorio para --server-type=devops)"
        echo ""
        echo "  --branch-name:        Nombre de de la rama que se quiere ejecutar, el parámetro"
        echo "                        está destinado al uso de ramas distintas a main, para"
        echo "                        pruebas de ramas de desarrollo, por ej. para la rama"
        echo "                        feature/nueva se debe usar el parámetro de la siguiente"
        echo "                        forma: --branch-name=feature/desa"
        exit 0
        ;;
    *)
        echo "Argumento no reconocido: $arg, use --help para ver la ayuda."
        exit 1
        ;;
    esac
done
remote_repo="https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/refs/heads/$repo_branch/assets"

# Se valida el parametro server-type y en el caso de ser devops se valida el token y la url
case "$server_type" in
devops)
    if [ -z "$ngrok_auth_token" ]; then
        echo "El argumento --ngrok-auth-token es obligatorio para el --server-type=devops"
        exit 1
    fi
    if [ -z "$ngrok_tunnel_url" ]; then
        echo "El argumento --ngrok-tunnel-url es obligatorio para el --server-type=devops"
        exit 1
    fi
    if [ -z "$duckdns_token" ]; then
        echo "El argumento --duckdns-token es obligatorio para el --server-type=devops"
        exit 1
    fi
    if [ -z "$email_for_keys" ]; then
        echo "El argumento --email-for-keys es obligatorio para el --server-type=devops"
        exit 1
    fi
    shift
    ;;
prod | uat) ;;
*)
    echo "Los valores permitidos para --server-type son: devops, prod, uat"
    exit 1
    ;;
esac

# Metodo helper para ejecutar comandos y reintentar en caso de error
exec_until_done() {
    local n=0
    local max=10
    local delay=5

    echo " |-> method: exec_until_done >>> $@"
    until "$@"; do
        n=$((n + 1))
        if [ $n -ge $max ]; then
            echo " |-> method: exec_until_done >>> Comando falló tras $n intentos: $*"
            return 1
        fi
        echo " |-> method: exec_until_done >>> Intento $n fallido. Reintentando en $delay segundos..."
        sleep $delay
    done
}
export -f exec_until_done

setup_remote_file() {
    echo " |-> method: setup_remote_file >>> lista de parametros de entrada:"
    local i=1
    for param in "$@"; do
        echo " |-> method: setup_remote_file >>> param $i: $param"
        i=$((i + 1))
    done
    echo " |-> method: setup_remote_file >>> fin de lista de parametros de entrada."

    # this params must be passed always, if not needed use a dummy value
    # name of the script to download
    local file_name=$1 && shift
    # remote repository URL
    local remote_repo=$1 && shift
    # local path to save the file
    [[ "$1" != "." ]] && local local_path=$HOME/$1 && shift || local local_path=$HOME && shift
    # type of the file (exec or service)
    local file_type=$1 && shift
    # whether to use envsubst or not
    local envsubst_flag=$1 && shift
    # command to run after all the other parameters
    local commands_to_run=$@

    local remote_file=$remote_repo/$file_name
    local file=$local_path/$file_name
    local temp_file=$(mktemp)

    echo " |-> method: setup_remote_file >>> file: $file"
    echo " |-> method: setup_remote_file >>> remote_file: $remote_file"
    exec_until_done curl -sSfL -o $temp_file $remote_file || { echo "Error descargando $remote_file" && exit 1 }

    echo " |-> method: setup_remote_file >>> envsubst_flag: $envsubst_flag"
    [[ "$envsubst_flag" == "envsubst-true" ]] && envsubst < $temp_file > $file || cp $temp_file $file
    chown $USER:$USER $file
    rm -f $temp_file
    
    echo " |-> method: setup_remote_file >>> file_type: $file_type"
    [[ "$file_type" == "exec" ]] && chmod +x $file
    [[ "$file_type" == "service" ]] && sudo ln -s $file /etc/systemd/system/

    echo "🔎📄 >>> BOF: $file"
    cat $file
    echo "🔎📄 >>> EOF: $file"

    [[ -n $commands_to_run ]] && "$commands_to_run"
}
export -f setup_remote_file

# Metodo para descargar y ejecutar scripts remotos
execute_remote_script() {
    echo " |-> method: execute_remote_script >>> lista de parametros de entrada:"
    local i=1
    for param in "$@"; do
        echo " |-> method: execute_remote_script >>> param $i: $param"
        i=$((i + 1))
    done
    echo " |-> method: execute_remote_script >>> fin de lista de parametros de entrada:"

    local script=$1
    local remote_repo=$2

    setup_remote_file $script $remote_repo '.' exec 'envsubst-false'

    shift
    ./$script $@

    rm $script
}
export -f execute_remote_script

execute_remote_script basics.sh $remote_repo

[[ $server_type == "devops" ]] &&
    execute_remote_script devops.sh $remote_repo $ngrok_auth_token $ngrok_tunnel_url $duckdns_token $email_for_keys
