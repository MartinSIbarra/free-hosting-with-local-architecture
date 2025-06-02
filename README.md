# Free Hosting with Local Architecture

## Índice
- [Objetivo](#objetivo)
- [Pre-requisitos](#pre-requisitos)
- [Instalación](#instalación)
- [Desarrollo](#desarrollo)

## Objetivo
El proyecto tiene como objetivo facilitar la creación de servidores para hosting de aplicaciones web. Utiliza **Vagrant** para crear máquinas virtuales: **DevOps**, **Production** y **UAT**, cada una con su propósito:

- La máquina **DevOps** tiene como objetivo exponer la aplicación web ejecutada por la máquina **Production** usando **ngrok** y **nginx**. También expone la aplicación web ejecutada por la máquina **UAT**.
- La máquina **Production** es la encargada de ejecutar la aplicación web que se expondrá a internet.
- La máquina **UAT** es la encargada de ejecutar la aplicación web del ambiente pre-productivo para pruebas de usuario.

## Pre-requisitos
La solución funciona con **Vagrant** y **VirtualBox**, por lo que es necesario tenerlos instalados en el sistema. También será necesario **curl** (opcional) para la descarga de los archivos de instalación. Además, para la utilización de la máquina **DevOps** será necesaria una cuenta en **Ngrok**.

### General
- #### [Instalar VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- #### [Instalar Vagrant](https://developer.hashicorp.com/vagrant/install)

### Accesorios
- #### Instalar curl (solo Linux)
  ```bash
  sudo apt update && sudo apt install -y curl
  ```

### DevOps Server
Para su funcionamiento, el servidor DevOps requiere un token de **ngrok** y un dominio. Ambos se pueden obtener de forma gratuita luego de registrarse.

- #### [Ngrok](https://ngrok.com/)

## Instalación
El repositorio cuenta con un instalador para **Linux** y **Windows**, para facilitar el proceso de instalación con una interfaz de usuario. Solo para la máquina **DevOps** es necesario realizar un paso intermedio para configurar **ngrok**.
Copiar y pegar el siguiente comando en la terminal. 
Antes de ejecutarlo, debe modificar `"/ruta/donde/guardar"` ó `"C:\Ruta\Donde\Guardar"` por la ruta deseada para descargar el archivo. Este comando descargará el archivo instalador y lo ejecutará para comenzar con la instalación de los servidores.

### Linux
```bash
destino="/ruta/donde/guardar"; curl -o "$destino/install.sh" https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/main/install.sh && chmod +x "$destino/install.sh" && "$destino/install.sh"
```

### Windows (powershell)
```powershell
$destino="C:\Ruta\Donde\Guardar"; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/main/install.ps1" -OutFile "$destino\install.ps1"; & "$destino\install.ps1"
```
Asegúrate de que PowerShell tenga permisos para ejecutar scripts:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Desarrollo
El proyecto se basa en obtener los scripts de forma remota desde el repositorio, para realizar pruebas sobre cambios que no se encuentran en la rama "main" se debe usar un parametro extra con el nombre de la rama que se desee utilizar, el siguiente ejemplo aplica a la rama **"feature/nueva"**, para cualquier otra rama se debe modificar el valor de la variable **branch** por el nombre de la rama deseada.

### Linux
```bash
branch="feature/nueva"; destino="."; curl -o $destino/install.sh https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/$branch/install.sh && chmod +x $destino/install.sh && $destino/install.sh --branch-name=$branch
```

### Windows (powershell)
```powershell
$branch="feature/nueva"; $destino="C:\Ruta\Donde\Guardar"; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/$branch/install.ps1" -OutFile "$destino\install.ps1"; & "$destino\install.ps1 --branch-name=$branch"
```
