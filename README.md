# Free Hosting with Local Architecture

## Linux

Copiar y pegar el siguiente comando en la terminal.
```Bash
destino="/ruta/donde/guardar"; curl -o "$destino/install.sh" https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/main/install.sh && chmod +x "$destino/install.sh" && "$destino/insstall.sh"
```


## Windows

Copiar y pegar el siguiente comando en la terminal.
```
$destino="C:\Ruta\Donde\Guardar"; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/main/install.ps1" -OutFile "$destino\install.ps1"; & "$destino\install.ps1"
```
