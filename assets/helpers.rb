# Obtengo el tipo de server en base a la carpeta donde se encuentra el Vagrantfile
def get_host_name(servers)
  host_name = File.basename(Dir.pwd)
  if servers.key?(host_name)
    puts "🚀 Utilizando entorno: #{servers[host_name][:name]}"
  else
    raise <<~ERROR
      
      ❌ ERROR: El nombre de la carpeta que contiene el Vagrantfile debe ser uno de los siguientes:
      - "prod-server" --> utilizada para generar el servidor de Producción
      - "uat-server" --> utilizada para generar el servidor de UAT
      - "devops-server" --> utilizada para generar el servidor de DevOps
      La carpeta actual se llama: '#{host_name}' por favor renombrela. 
    ERROR
  end
  return host_name
end

def get_ngrok_data(host_name, servers)
  ngrok_auth_token = nil
  ngrok_tunnel_url = nil
  if servers[host_name][:tunnel_config_required]
    ngrok_auth_token = ENV['NGROK_AUTH_TOKEN']
    ngrok_tunnel_url = ENV['NGROK_TUNNEL_URL']
    if !ngrok_auth_token || ngrok_auth_token.empty? || !ngrok_tunnel_url || ngrok_tunnel_url.empty?
      raise <<~ERROR
        ❌ ERROR: El sevidor de DevOps requiere la configuracion de ngrok.
        Se deben exportar las siguientes variables:
        export AUTH_TOKEN="su_token_de_ngrok"
        export TUNNEL_URL="su_url_de_ngrok"
      ERROR
    end
  end
  return {ngrok_auth_token: ngrok_auth_token, ngrok_tunnel_url: ngrok_tunnel_url}
end


# Obtiene el sistema operativo
def get_operative_system
  if RUBY_PLATFORM =~ /linux/
    return "linux"
  elsif RUBY_PLATFORM =~ /darwin/
    return "macos"      
  elsif RUBY_PLATFORM =~ /mingw|mswin|cygwin/
    return "windows"
  else
    raise "❌ Sistema operativo no soportado: #{RUBY_PLATFORM}"
  end
end

# Obtiene la interfaz de red con puerta de enlace
def get_bridge_interface(os)
  bridge_interface = nil
  if os == "linux"
    output = `ip route`
    line = output.lines.find { |l| l.include?('default') }
    bridge_interface = line.split[4] if line  # En Linux, interfaz está en la 5ta palabra (índice 4)
    
  elsif os == "macos"
    output = `route get default`
    line = output.lines.find { |l| l.include?('interface:') }
    bridge_interface = line.split[1].strip if line  # Ejemplo: "interface: en0"
    
  else # windows
    output = `powershell -Command "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null }).InterfaceDescription"`
    bridge_interface = output.strip
  end

  if bridge_interface.nil? || bridge_interface.empty?
    raise <<~ERROR
    
    "❌ No se pudo determinar la interfaz de red con puerta de enlace."
    ERROR
  end
  puts "🔗 Usando interfaz bridge: #{bridge_interface}"
  return bridge_interface
end

# Obtiene la ruta del ISO del Guest Additions
def get_guest_additions_iso(os)
  if os == "linux"
    return "/usr/share/virtualbox/VBoxGuestAdditions.iso"  
  elsif os == "macos"
    return "/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso"
  else # windows
    return "C:\\Program Files\\Oracle\\VirtualBox\\VBoxGuestAdditions.iso"
  end
end
