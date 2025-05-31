def configuracion_inicial()
  return <<-SHELL
    echo "🔧 > Actualizando el Package Manager e instalando escenciales..."
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y build-essential dkms busybox linux-headers-amd64
    echo "✅ > Package Manager actualizado."
    echo "🔧 > Configurando locales..."
    # Descomentar es_AR.UTF-8 si está comentada en /etc/locale.gen
    sudo sed -i '/es_AR.UTF-8/s/^# //g' /etc/locale.gen
    sudo locale-gen es_AR.UTF-8 en_US.UTF-8 # Generar los locales
    # Establecer los locales predeterminados del sistema
    sudo update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=es_AR.UTF-8 LC_NUMERIC=es_AR.UTF-8 LC_TIME=es_AR.UTF-8 LC_MONETARY=es_AR.UTF-8 LC_PAPER=es_AR.UTF-8 LC_NAME=es_AR.UTF-8 LC_ADDRESS=es_AR.UTF-8 LC_TELEPHONE=es_AR.UTF-8 LC_MEASUREMENT=es_AR.UTF-8 LC_IDENTIFICATION=es_AR.UTF-8
    echo "✅ > Locales configurados."
  SHELL
end

def accesorios()
  return <<-SHELL
    echo "🔧 > Instalando Accesorios..."
    sudo apt-get install -y curl
    echo "✅ > Accesorios instalados."
    SHELL
  end
    
def virtualbox_ga() 
  return <<-SHELL
    echo "🔧 > Instalando Virtual Box Guest Additions..."
    sleep 10
    sudo mkdir -p /mnt/cdrom
    sudo mount /dev/sr0 /mnt/cdrom || (echo "No se pudo montar /dev/sr0. Verifique si la ISO está adjunta o si la ruta es correcta." && exit 1)
   
    sudo /mnt/cdrom/VBoxLinuxAdditions.run 2>&1 || true

    sudo umount /mnt/cdrom || echo "No se pudo desmontar /mnt/cdrom. Puede requerir un reinicio."
    (
    echo "✅ > Virtual Box Guest Additions instalados."
    echo "⚠️ Para aplicar los cambios en la ejecucion de la maquina virtual, es necesario"
    echo "   reiniciar la maquina virtual de vagran 2 veces."
    echo "   Esto puede realizarse usando \"vagrant reload\" o \"vagrant halt && vagrant up\" x2"
    echo "   Esta accion solo es requeria la \"primera vez\"."
    )
  SHELL
end 

def remote_provision_script(repo_branch, remote_repo, server_type)
  ngrok_data = get_ngrok_data(host, servers)
  return <<-SHELL
    MAX_RETRIES=10
    RETRY_DELAY=5
    ATTEMPT=1
    LOG_DIR="$/home/vagrant/logs"
    TMP_DIR="$/home/vagrant/tmp"
    SCRIPT_NAME="provision"
    LOG_FILE="$LOG_DIR/$SCRIPT_NAME-download.log"
    SCRIPT_FILE="$TMP_DIR/tmp_script.sh"
    REMOTE_REPO="#{remote_repo}"

    su - vagrant -c "mkdir -p $LOG_DIR $TMP_DIR"
    su - vagrant -c "touch $LOG_FILE"
    su - vagrant -c "touch $SCRIPT_FILE"

    echo "Script de provisionamiento $SCRIPT_NAME-retries"
    echo "Inicio del provisionamiento: $(date)"
    echo "Script de provisionamiento $SCRIPT_NAME-retries" >> "$LOG_FILE"
    echo "Inicio del provisionamiento: $(date)" >> "$LOG_FILE"

    until su - vagrant -c "curl -sSfL $REMOTE_REPO/$SCRIPT_NAME.sh -o $SCRIPT_FILE"; do
      echo "[$(date)] Intento $ATTEMPT: Error al descargar el script." | su - vagrant -c "tee -a $LOG_FILE"
      ATTEMPT=$((ATTEMPT + 1))
      if [ $ATTEMPT -gt $MAX_RETRIES ]; then
        echo "[$(date)] Fallo tras $MAX_RETRIES intentos. Abortando." | su - vagrant -c "tee -a $LOG_FILE"
        exit 1
        fi
        echo "Reintentando en $RETRY_DELAY segundos..." | su - vagrant -c "tee -a $LOG_FILE"
        sleep $RETRY_DELAY
    done

    echo "[$(date)] Descarga exitosa del script." | su - vagrant -c "tee -a $LOG_FILE"
    chmod +x "$SCRIPT_FILE"
    su - vagrant -c "export REPO_BRANCH=#{repo_branch}"
    su - vagrant -c "source $SCRIPT_FILE --server-type=#{server_type} --ngrok-auth-token=#{ngrok_data[:ngrok_auth_token]} --ngrok-tunnel-url=#{ngrok_data[:ngrok_tunnel_url]}"
    rm -rf "$TMP_DIR"
    su - vagrant -c "source /home/vagrant/.bashrc"
  SHELL
end