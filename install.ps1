$showMenu = $true
$option = ""
$serverPath = ""
$serverLabel = ""
$devopsServerLabel = "DevOps Server"
$prodServerLabel = "Production Server"
$uatServerLabel = "UAT Server"
$input = ""
$branch = if ($env:REPO_BRANCH) { $env:REPO_BRANCH } else { "main" }

function Pause($message = "Presiona una tecla para continuar...") {
    Write-Host ""
    Write-Host $message
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

while ($showMenu) {
    Clear-Host
    Write-Host "___________________________________________________________`n"
    Write-Host ""
    Write-Host " Bienvenido al menú de instalación de servidores virtuales"
    Write-Host " Selecciona una opción para continuar, se generará una "
    Write-Host " máquina virtual con Vagrant y VirtualBox "
    Write-Host "___________________________________________________________`n"
    Write-Host ""
    Write-Host "  1) $devopsServerLabel"
    Write-Host "  2) $prodServerLabel"
    Write-Host "  3) $uatServerLabel"

    if ($input -notin 1,2,3) {
        Write-Host "`n  0) Salir"
        Write-Host "`n  Selecciona una opción (1-3) o 0 para salir:"
    }

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $input = $key.Character

    switch ($input) {
        "0" {
            Write-Host "`n  Saliendo... `n"
            exit
        }
        "1" {
            $serverPath = "devops-server"
            $serverLabel = $devopsServerLabel
        }
        "2" {
            $serverPath = "prod-server"
            $serverLabel = $prodServerLabel
        }
        "3" {
            $serverPath = "uat-server"
            $serverLabel = $uatServerLabel
        }
        default {
            continue
        }
    }

    Write-Host "`n  Has elegido la opción $input - $serverLabel"

    if (Test-Path "$serverPath\Vagrantfile") {
        Write-Host "`n  Ya existe la máquina virtual para esta opción, no se puede crear."
        Pause
        continue
    }

    if ($input -eq "1") {
        $env:NGROK_AUTH_TOKEN = Read-Host "  - Ingresar token para ngrok"
        if ($env:NGROK_AUTH_TOKEN) {
            $env:NGROK_TUNNEL_URL = Read-Host "  - Ingresar URL para ngrok"
            if (-not $env:NGROK_TUNNEL_URL) {
                $input = ""
                continue
            }
        }
    }

    Write-Host "`n  Presiona Enter para confirmar ó ESC para volver al menú."
    while ($true) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.VirtualKeyCode -eq 13) {  # Enter
            $option = $input
            $showMenu = $false
            break
        } elseif ($key.VirtualKeyCode -eq 27) {  # Escape
            $input = ""
            break
        }
    }
}

New-Item -ItemType Directory -Force -Path $serverPath | Out-Null
Set-Location $serverPath

function Execute-Command {
    param (
        [string]$command
    )
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

# Descargar Vagrantfile
$rawUrl = "https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/refs/heads/$branch/assets/Vagrantfile"
Execute-Command "Invoke-WebRequest -Uri '$rawUrl' -OutFile 'Vagrantfile' -UseBasicParsing"

# Reemplazar rama en Vagrantfile
(Get-Content Vagrantfile) -replace 'repo_branch = "main"', "repo_branch = `"$branch`"" | Set-Content Vagrantfile

Write-Host "`n  Instalando $serverLabel..."
Write-Host ""

# Iniciar Vagrant
vagrant up
vagrant reload --provision-with post1,post2,post3
