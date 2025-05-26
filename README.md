# Free Hosting with Local Architecture

## Linux

Copiar y pegar el siguiente comando en la terminal. Antes de ejecutar debe modiifcar ***"/ruta/donde/guardar"*** por la ruta deseada para descargar el archivo. Este comando descargará el archivo "install.sh" y lo ejecutará para comenzar con la instalación de los servidores.

```Bash
destino="/ruta/donde/guardar"; curl -o "$destino/install.sh" https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/main/install.sh && chmod +x "$destino/install.sh" && "$destino/install.sh"
```


## Windows

Copiar y pegar el siguiente comando en la terminal. Antes de ejecutar debe modiifcar ***"C:\Ruta\Donde\Guardar"*** por la ruta deseada para descargar el archivo. Este comando descargará el archivo "install.ps1" y lo ejecutará para comenzar con la instalación de los servidores.

```PowerShell
$destino="C:\Ruta\Donde\Guardar"; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/main/install.ps1" -OutFile "$destino\install.ps1"; & "$destino\install.ps1"
```
