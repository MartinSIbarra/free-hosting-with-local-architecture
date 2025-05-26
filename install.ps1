# PowerShell Script: install-server.ps1

$showMenu = $true
$option = ""
$serverPath = ""
$serverLabel = ""
$devopsServerLabel = "DevOps Server"
$prodServerLabel = "Production Server"
$uatServerLabel = "UAT Server"

function Show-Menu {
    Clear-Host
    Write-Host "___________________________________________________________"
    Write-Host ""
    Write-Host " Bienvenido al menú de instalación de servidores virtuales"
    Write-Host " Selecciona una opción para continuar, se generará una "
    Write-Host " máquina virtual con Vagrant y VirtualBox "
    Write-Host "___________________________________________________________"
    Write-Host ""
    Write-Host "  1) $devopsServerLabel"
    Write-Host "  2) $prodServerLabel"
    Write-Host "  3) $uatServerLabel"
    Write-Host ""
    Write-Host "  0) Salir"
    Write-Host ""
    Write-Host "  Selecciona una opción (1-3) o 0 para salir:"
}

function Execute-Command($command) {
    $maxRetries = 10
    $retryDelay = 5
    $attempt = 1
    while ($true) {
        try {
            Invoke-Expression $command
            break
        } catch {
            if ($attempt -ge $maxRetries) {
                Write-Host "[$(Get-Date)] Fallo tras $maxRetries intentos. Abortando."
                exit 1
            }
            $attempt++
            Start-Sleep -Seconds $retryDelay
        }
    }
}

while ($showMenu) {
    Show-Menu
    $input = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

    switch ($input) {
        '0' {
            Write-Host "`n  Saliendo..."
            exit
        }
        '1' { $serverPath = "devops-server"; $serverLabel = $devopsServerLabel }
        '2' { $serverPath = "prod-server"; $serverLabel = $prodServerLabel }
        '3' { $serverPath = "uat-server"; $serverLabel = $uatServerLabel }
        default { continue }
    }

    Write-Host "`n  Has elegido la opción $input - $serverLabel"

    if (Test-Path "$serverPath/Vagrantfile") {
        Write-Host "  Ya existe la máquina virtual para esta opción, no se puede crear."
        Write-Host "  Presiona cualquier tecla para volver al menú."
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        continue
    }

    Write-Host "  Presiona Enter para confirmar ó ESC para volver al menú."

    while ($true) {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.VirtualKeyCode -eq 13) { # Enter
            $option = $input
            $showMenu = $false
            break
        } elseif ($key.VirtualKeyCode -eq 27) { # ESC
            break
        }
    }
}

New-Item -ItemType Directory -Force -Path $serverPath | Out-Null
Set-Location -Path $serverPath

$ngrokConfigFile = "ngrok.conf"
if ($option -eq "1") {
    if (-not (Test-Path $ngrokConfigFile)) {
        Set-Content -Path $ngrokConfigFile -Value "AUTH_TOKEN=<su_token_de_ngrok>`nTUNNEL_URL=<su_url_de_ngrok>"
        Write-Host ""
        Write-Host "  Se creó el archivo de configuración de ngrok: $serverPath\$ngrokConfigFile"
        Write-Host "  Editá el archivo y agregá tu token de ngrok y la URL del túnel."
        Write-Host "  Luego debes volver a ejecutar este script."
        Write-Host "  Tené en cuenta que si se realiza la instalación del servidor de DevOps"
        Write-Host "  sin agregar el token y URL, el servidor de DevOps no funcionará correctamente."
        Write-Host "`n  Presione cualquier tecla para continuar..."
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Write-Host ""
        exit
    }
}

Execute-Command 'Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/refs/heads/main/assets/Vagrantfile" -OutFile "Vagrantfile"'

Write-Host "  Instalando $serverLabel..."
Write-Host ""
vagrant up
vagrant reload --provision-with post1,post2,post3
