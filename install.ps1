# Define las etiquetas
$devopsLabel = "DevOps Server"
$prodLabel = "Production Server"
$uatLabel = "UAT Server"

$showMenu = $true
$option = ""
$serverPath = ""
$serverLabel = ""

function Show-Menu {
    Clear-Host
    Write-Host "___________________________________________________________`n"
    Write-Host " Bienvenido al menú de instalación de servidores virtuales"
    Write-Host " Selecciona una opción para continuar, se generará una"
    Write-Host " máquina virtual con Vagrant y VirtualBox"
    Write-Host "___________________________________________________________`n"
    Write-Host "  1) $devopsLabel"
    Write-Host "  2) $prodLabel"
    Write-Host "  3) $uatLabel"
    Write-Host ""
    Write-Host "  0) Salir"
    Write-Host ""
    Write-Host "  Selecciona una opción (1-3) o 0 para salir:"
}

function Wait-For-Key {
    $key = $null
    while ($null -eq $key) {
        $key = [System.Console]::ReadKey($true)
    }
    return $key
}

function Execute-Command($command) {
    $maxRetries = 10
    $retryDelay = 5
    $attempt = 1
    while ($attempt -le $maxRetries) {
        try {
            Invoke-Expression $command
            return
        } catch {
            if ($attempt -eq $maxRetries) {
                Write-Host "[ERROR] Falló tras $maxRetries intentos. Abortando."
                exit 1
            }
            Start-Sleep -Seconds $retryDelay
            $attempt++
        }
    }
}

while ($showMenu) {
    Show-Menu
    $key = Wait-For-Key
    $input = $key.KeyChar

    switch ($input) {
        '0' {
            Write-Host "`nSaliendo..."
            exit 0
        }
        '1' {
            $serverPath = "devops-server"
            $serverLabel = $devopsLabel
        }
        '2' {
            $serverPath = "prod-server"
            $serverLabel = $prodLabel
        }
        '3' {
            $serverPath = "uat-server"
            $serverLabel = $uatLabel
        }
        default {
            continue
        }
    }

    Write-Host "`n  Has elegido la opción $input - $serverLabel"

    $vagrantFilePath = Join-Path $serverPath "Vagrantfile"
    if (Test-Path $vagrantFilePath) {
        Write-Host "  Ya existe la máquina virtual para esta opción. No se puede crear."
        Write-Host "  Presiona cualquier tecla para volver al menú."
        Wait-For-Key | Out-Null
        continue
    } else {
        Write-Host "  Presiona Enter para confirmar o Esc para volver al menú."
        while ($true) {
            $confirmKey = Wait-For-Key
            if ($confirmKey.Key -eq 'Enter') {
                $option = $input
                $showMenu = $false
                break
            } elseif ($confirmKey.Key -eq 'Escape') {
                break
            }
        }
    }
}

# Validación para DevOps Server: crear ngrok.conf si no existe
if ($option -eq '1') {
    $ngrokConfigFile = Join-Path $serverPath "ngrok.conf"
    if (-not (Test-Path $ngrokConfigFile)) {
        New-Item -Path $ngrokConfigFile -ItemType File -Force | Out-Null
        Set-Content -Path $ngrokConfigFile -Value @"
AUTH_TOKEN=<su_token_de_ngrok>
TUNNEL_URL=<su_url_de_ngrok>
"@
        Write-Host "`n  Se creó el archivo de configuración: $ngrokConfigFile"
        Write-Host "  Editá el archivo y agregá tu token y URL de ngrok."
        Write-Host "  Luego, volvé a ejecutar este script."
        Write-Host "`n  Presiona cualquier tecla para salir..."
        Wait-For-Key | Out-Null
        exit 0
    }
}

# Ejecutar curl y crear entorno
New-Item -Path $serverPath -ItemType Directory -Force | Out-Null
Set-Location -Path $serverPath

Execute-Command "curl -sSOfL https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/refs/heads/main/assets/Vagrantfile"

Write-Host "`n  Instalando $serverLabel..."
vagrant up
vagrant reload --provision-with post1,post2,post3
