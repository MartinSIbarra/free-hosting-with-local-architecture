param(
    [string]$branchName = "main"
)

function Show-Help {
    Write-Host ""
    Write-Host "  Uso: .\install.ps1 [-branchName <branch/name>]"
    Write-Host ""
    Write-Host "  -branchName:   Nombre de la rama que se quiere ejecutar, el parámetro"
    Write-Host "                 está destinado al uso de ramas distintas a main, para"
    Write-Host "                 pruebas de ramas de desarrollo, por ej. para la rama"
    Write-Host "                 feature/nueva se debe usar el parámetro de la siguiente"
    Write-Host "                 forma: -branchName feature/desa"
    Write-Host ""
    exit 0
}

function Validate-Arguments {
    param([string[]]$args)
    foreach ($arg in $args) {
        if ($arg -eq "--help" -or $arg -eq "-h") {
            Show-Help
        }
    }
}

function Show-DevOps-Server-Menu {
    param(
        [ref]$ngrokAuthToken,
        [ref]$ngrokTunnelUrl,
        [ref]$duckdnsToken,
        [ref]$emailForKeys
    )
    Write-Host "`n  Se requieren los siguientes datos para configurar el servidor DevOps:"
    if ($ngrokAuthToken.Value) { Write-Host "   - Token de Ngrok: $($ngrokAuthToken.Value)" }
    if ($ngrokTunnelUrl.Value) { Write-Host "   - URL de Ngrok: $($ngrokTunnelUrl.Value)" }
    if ($duckdnsToken.Value) { Write-Host "   - TOKEN de DuckDNS: $($duckdnsToken.Value)" }
    if ($emailForKeys.Value) { Write-Host "   - Email para VPN keys: $($emailForKeys.Value)" }

    if (-not $ngrokAuthToken.Value) { $ngrokAuthToken.Value = Read-Host "   - Ingresar TOKEN para Ngrok" }
    if (-not $ngrokTunnelUrl.Value) { $ngrokTunnelUrl.Value = Read-Host "   - Ingresar URL para Ngrok" }
    if (-not $duckdnsToken.Value) { $duckdnsToken.Value = Read-Host "   - Ingresar TOKEN para DuckDNS" }
    if (-not $emailForKeys.Value) { $emailForKeys.Value = Read-Host "   - Ingresar EMAIL para VPN keys" }

    if ($ngrokAuthToken.Value -and $ngrokTunnelUrl.Value -and $duckdnsToken.Value -and $emailForKeys.Value) {
        $script:devopsDataComplete = $true
        Write-Host "`n  Todos los datos necesarios han sido proporcionados."
    } else {
        Write-Host "`n  Faltan datos necesarios para continuar. Por favor, completa todos los campos."
    }
}

function Show-Server-Menu {
    $devopsServerLabel = "DevOps Server"
    $prodServerLabel = "Production Server"
    $uatServerLabel = "UAT Server"
    $script:serverComplete = $false
    $script:devopsDataComplete = $false

    while (-not $script:serverComplete) {
        Clear-Host
        Write-Host "___________________________________________________________"
        Write-Host ""
        Write-Host " Bienvenido al menú de instalación de servidores virtuales"
        Write-Host " Selecciona una opción para continuar, se generará una "
        Write-Host " máquina virtual con Vagrant y VirtualBox "
        Write-Host "___________________________________________________________"
        Write-Host ""
        if (-not $script:server) {
            Write-Host "  1) $devopsServerLabel"
            Write-Host "  2) $prodServerLabel"
            Write-Host "  3) $uatServerLabel"
            Write-Host "`n  0) Salir"
            $script:server = Read-Host "`n  Selecciona una opción de 1 a 3 ó 0 para salir"
            if ($script:server -eq "0") {
                Write-Host "`n  Saliendo del instalador..."
                Write-Host ""
                exit 0
            }
        }
        switch ($script:server) {
            "1" {
                $script:serverDir = "devops-server"
                $script:serverLabel = $devopsServerLabel
                Show-DevOps-Server-Menu -ngrokAuthToken ([ref]$script:ngrokAuthToken) -ngrokTunnelUrl ([ref]$script:ngrokTunnelUrl) -duckdnsToken ([ref]$script:duckdnsToken) -emailForKeys ([ref]$script:emailForKeys)
                if ($script:devopsDataComplete) { $script:serverComplete = $true }
            }
            "2" {
                $script:serverDir = "prod-server"
                $script:serverLabel = $prodServerLabel
                $script:serverComplete = $true
            }
            "3" {
                $script:serverDir = "uat-server"
                $script:serverLabel = $uatServerLabel
                $script:serverComplete = $true
            }
            default {
                $script:server = $null
            }
        }
    }
}

function Execute-Command {
    param([string]$command)
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

# Main
$script:server = $null
$script:ngrokAuthToken = $null
$script:ngrokTunnelUrl = $null
$script:duckdnsToken = $null
$script:emailForKeys = $null
$script:serverDir = ""
$script:serverLabel = ""

Validate-Arguments $args

$remoteRepo = "https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/refs/heads/$branchName/assets"

Show-Server-Menu

if (-not (Test-Path $script:serverDir)) {
    New-Item -ItemType Directory -Path $script:serverDir | Out-Null
}
Set-Location $script:serverDir

# Descargar Vagrantfile con reintentos
Execute-Command "Invoke-WebRequest -Uri $remoteRepo/Vagrantfile -OutFile Vagrantfile"

# Reemplazar variables en el Vagrantfile
(Get-Content Vagrantfile) -replace 'repo_branch = "main"', "repo_branch = `"$branchName`"" |
    Set-Content Vagrantfile
(Get-Content Vagrantfile) -replace 'ngrok_auth_token: ""', "ngrok_auth_token: `"$script:ngrokAuthToken`"" |
    Set-Content Vagrantfile
(Get-Content Vagrantfile) -replace 'ngrok_tunnel_url: ""', "ngrok_tunnel_url: `"$script:ngrokTunnelUrl`"" |
    Set-Content Vagrantfile
(Get-Content Vagrantfile) -replace 'duckdns_token: ""', "duckdns_token: `"$script:duckdnsToken`"" |
    Set-Content Vagrantfile
(Get-Content Vagrantfile) -replace 'email_for_keys: ""', "email_for_keys: `"$script:emailForKeys`"" |
    Set-Content Vagrantfile

Write-Host "  Instalando $($script:serverLabel)..."
Write-Host ""
# Ejecutar Vagrant (debe estar instalado en el sistema)
Invoke-Expression "vagrant up"
Invoke-Expression "vagrant reload --provision-with post1,post2,post3"