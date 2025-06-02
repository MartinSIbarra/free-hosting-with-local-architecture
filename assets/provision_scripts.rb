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

def remote_provision_script(repo_branch, remote_repo, server_type, ngrok_data)
  return <<-SHELL
    max_retries=10
    retry_delay=5
    attempt=1
    log_dir="/home/vagrant/logs"
    tmp_dir="/home/vagrant/tmp"
    script_name="provision"
    log_file="$log_dir/$script_name-download.log"
    script_file="$tmp_dir/tmp_script.sh"
    remote_repo="#{remote_repo}"

    su - vagrant -c "mkdir -p $log_dir $tmp_dir"
    su - vagrant -c "touch $log_file"
    su - vagrant -c "touch $script_file"

    echo "Script de provisionamiento $script_name-retries"
    echo "Inicio del provisionamiento: $(date)"
    echo "Script de provisionamiento $script_name-retries" >> "$log_file"
    echo "Inicio del provisionamiento: $(date)" >> "$log_file"

    until su - vagrant -c "curl -sSfL $remote_repo/$script_name.sh -o $script_file"; do
      echo "[$(date)] Intento $attempt: Error al descargar el script." | su - vagrant -c "tee -a $log_file"
      attempt=$((attempt + 1))
      if [ $attempt -gt $max_retries ]; then
        echo "[$(date)] Fallo tras $max_retries intentos. Abortando." | su - vagrant -c "tee -a $log_file"
        exit 1
        fi
        echo "Reintentando en $retry_delay segundos..." | su - vagrant -c "tee -a $log_file"
        sleep $retry_delay
    done

    echo "[$(date)] Descarga exitosa del script." | su - vagrant -c "tee -a $log_file"
    chmod +x "$script_file"
    su - vagrant -c "source $script_file --server-type=#{server_type} --ngrok-auth-token=#{ngrok_data[:ngrok_auth_token]} --ngrok-tunnel-url=#{ngrok_data[:ngrok_tunnel_url]} --branch-name=#{repo_branch}"
    rm -rf "$tmp_dir"
    su - vagrant -c "source /home/vagrant/.bashrc"
  SHELL
end