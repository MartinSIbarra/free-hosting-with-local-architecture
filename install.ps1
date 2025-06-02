# PowerShell Script: install-server.ps1

param (
    [string]$branchName = "main"
)

# Argument parsing (para compatibilidad con --branch-name=...)
foreach ($arg in $args) {
    if ($arg -like "--branch-name=*") {
        $branchName = $arg -replace "--branch-name=", ""
    } elseif ($arg -eq "--help") {
        Write-Host ""
        Write-Host "  Uso: install-server.ps1 [--branch-name=<branch/name>]"
        Write-Host ""
        Write-Host "  --branch-name:   Nombre de la rama que se quiere ejecutar, el parámetro"
        Write-Host "                   está destinado al uso de ramas distintas a main, por ejemplo:"
        Write-Host "                   --branch-name=feature/desa"
        Write-Host ""
        exit
    } else {
        Write-Host "Argumento no reconocido: $arg, use --help para ver la ayuda."
        exit 1
    }
}

$showMenu = $true
$option = ""
$serverPath = ""
$serverLabel = ""
$input = ""
$devopsServerLabel = "DevOps Server"
$prodServerLabel = "Production Server"
$uatServerLabel = "UAT Server"
$remoteRepo = "https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/refs/heads/$branchName/assets"
$ngrokAuthToken = ""
$ngrokTunnelUrl = ""

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

    if ($input -notin '1', '2', '3') {
        Write-Host ""
        Write-Host "  0) Salir"
        Write-Host ""
        Write-Host "  Selecciona una opción (1-3) o 0 para salir:"
    }

    $input = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

    switch ($input) {
        '0' {
            Write-Host "`n  Saliendo...`n"
            exit
        }
        '1' { $serverPath = "devops-server"; $serverLabel = $devopsServerLabel }
        '2' { $serverPath = "prod-server"; $serverLabel = $prodServerLabel }
        '3' { $serverPath = "uat-server"; $serverLabel = $uatServerLabel }
        default { continue }
    }

    Write-Host "`n  Has elegido la opción $input - $serverLabel"

    if (Test-Path "$serverPath/Vagrantfile") {
        Write-Host "`n  Ya existe la máquina virtual para esta opción, no se puede crear."
        Write-Host "  Presiona cualquier tecla para volver al menú."
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        continue
    }

    if ($input -eq '1') {
        $ngrokAuthToken = Read-Host "  - Ingresar token para ngrok"
        if ($ngrokAuthToken) {
            $ngrokTunnelUrl = Read-Host "  - Ingresar url para ngrok"
        }
        if (-not $ngrokTunnelUrl) {
            $input = ""
            continue
        }
    }

    Write-Host "`n  Presiona Enter para confirmar ó ESC para volver al menú."
    while ($true) {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.VirtualKeyCode -eq 13) {
            $option = $input
            $showMenu = $false
            break
        } elseif ($key.VirtualKeyCode -eq 27) {
            $input = ""
            break
        }
    }
}

# Crear carpeta y cambiar directorio
New-Item -ItemType Directory -Force -Path $serverPath | Out-Null
Set-Location -Path $serverPath

# Descargar el Vagrantfile con reintentos
Execute-Command "Invoke-WebRequest -Uri `"$remoteRepo/Vagrantfile`" -OutFile `"Vagrantfile`""

# Reemplazar valores dentro del Vagrantfile
(Get-Content "Vagrantfile") -replace 'repo_branch = "main"', "repo_branch = `"$branchName`"" |
    ForEach-Object {
        $_ -replace 'ngrok_auth_token: ""', "ngrok_auth_token: `"$ngrokAuthToken`""
    } | ForEach-Object {
        $_ -replace 'ngrok_tunnel_url: ""', "ngrok_tunnel_url: `"$ngrokTunnelUrl`""
    } | Set-Content "Vagrantfile"

Write-Host ""
Write-Host "  Instalando $serverLabel..."
Write-Host ""
vagrant up
vagrant reload --provision-with post1,post2,post3
