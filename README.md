# Free Hosting with Local Architecture
## Índice
- [Objetivo](##Objetivo.)
- [Pre-requisitos](##Pre-requisitos.)
- [Instalación](##Instalación.)


## Objetivo.
El proyecto tiene como objetivo el facilitar la creación de servidores para hosting de aplicaciones webs, utiliza Vagrant para crear maquinas virtuales DevOps, Production y UAT. Cada una de ellas con su proposito.
- La maquina de **DevOps** tiene como objetivo exponer la aplicación web ejecutada por la maquina **Production** usando ngrok y nginx. Tambien expone la aplicacion web ejecutada por la maquina **UAT**.
- La maquina de **Production** es la encargada de ejecutar la aplicación web que se expondra a internet.
- La maquina de **UAT** es la encargada de ejecutar la aplicación web de ambiente pre-productivo para pruebas de usuario.

## Pre-requisitos.
La solución funciona con **Vagrant** y **Virtual Box**, para lo cual es necesario tenerlos instalados en el sistema. Tambien será necesario **curl** (opcional) para la descarga de los archivos de instalación. También para la utilización de la maquina de DevOps sera necesario una cuenta en **Ngrok**.
- ### General.
  - #### [Instalar Virtual Box](https://www.virtualbox.org/wiki/Downloads)
  - #### [Instalar Vagrant](https://developer.hashicorp.com/vagrant/install)

- ### Accesorios.
  - #### Instalar curl (solo Linux).
    ```Bash
    sudo apt update && sudo apt install -y curl
    ```

- ### DevOps Server.
  Para su funcionamiento el servidor de dev ops requiere un token de ngrok y un dominio. Ambos se puden obtener de forma gratuita luego de registrarse.
  - #### [Ngrok](https://ngrok.com/)


## Instalación.
El repositorio cuenta con un instalable para **Linux** y **Windows**, que permite automatizar el proceso de instación, solo para la maquina de DevOps es necesario hacer un paso intermedio para configurar Ngrok.

- ### Linux.
  Copiar y pegar el siguiente comando en la terminal. Antes de ejecutar debe modiifcar ***"/ruta/donde/guardar"*** por la ruta deseada para descargar el archivo. Este comando descargará el archivo "install.sh" y lo ejecutará para comenzar con la instalación de los servidores.
  ```Bash
  destino="/ruta/donde/guardar"; curl -o "$destino/install.sh" https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/main/install.sh && chmod +x "$destino/install.sh" && "$destino/install.sh"
  ```

- ### Windows.
  Copiar y pegar el siguiente comando en la terminal. Antes de ejecutar debe modiifcar ***"C:\Ruta\Donde\Guardar"*** por la ruta deseada para descargar el archivo. Este comando descargará el archivo "install.ps1" y lo ejecutará para comenzar con la instalación de los servidores.
  ```PowerShell
  $destino="C:\Ruta\Donde\Guardar"; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/main/install.ps1" -OutFile "$destino\install.ps1"; & "$destino\install.ps1"
  ```
