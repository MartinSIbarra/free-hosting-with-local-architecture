load './provision_scripts.rb'
load './helpers.rb'

# Direccion del repositorio remoto para la creacion de vagrant
remote_repo = "https://raw.githubusercontent.com/MartinSIbarra/localhost-configs/refs/heads/main/files"

# Configuración de maquina vagrant para la distintos entornos
servers = {
  "devops-server" => { 
    server_type: "devops",
    name: "DevOps",
    ip: "192.168.0.1", 
    ssh_port: 2230,
    tunnel_config_required: true
  },
  "prod-server" => {
    server_type: "prod",
    name: "Producción",
    ip: "192.168.0.2", 
    ssh_port: 2231,
    tunnel_config_required: false
  },
  "uat-server" => {
    server_type: "uat",
    name: "UAT",
    ip: "192.168.0.3", 
    ssh_port: 2232,
    tunnel_config_required: false
  }
}
# Configuración de las carpetas compartidas
shared_folders = [
  {host: ".", guest: "/home/vagrant/fs"},
]

# Incio del script para la configuracion de la maquina virtual
Vagrant.configure("2") do |config|
  
  host = get_host_name(servers)
  ngrok_data = get_ngrok_data(host, servers)
  os = get_operative_system()
  bridge_interface = get_bridge_interface(os)
  guest_additions_iso = get_guest_additions_iso(os)
  
  config.vm.box = "debian/bookworm64"
  config.vm.box_version = "12.20250126.1"
  config.vm.hostname = host
  config.vm.network "forwarded_port", guest: 22, host: servers[host][:ssh_port], id: "ssh"
  config.vm.network "public_network", ip: servers[host][:ip], bridge: bridge_interface
  shared_folders.each do |shared_folder|
    config.vm.synced_folder shared_folder[:host], shared_folder[:guest]
  end
  config.vm.provider "virtualbox" do |vb|
    # vb.memory = "1024"
    vb.name = host
    vb.customize ["storageattach", :id,
      "--storagectl", "SATA Controller",
      "--port", "2", "--device", "0",
      "--type", "dvddrive",
      "--medium", guest_additions_iso]
  end

  #Aprovisionamiento de la maquina virtual con lo minimo
  config.vm.provision "shell", inline: accesorios()
  config.vm.provision "shell", inline: virtualbox_ga()
  #Aprovisionamiento de la maquina virtual con el script para la configuracion para el servidor
  config.vm.provision "shell", inline: remote_provision_script(remote_repo, servers[host][:server_type], ngrok_data[:ngrok_auth_token], ngrok_data[:ngrok_tunnel_url])
end
