# ...existing code...
Param(
    [string]$branchName = "main"
)

$showMenu = $true
$option = ""
$serverPath = ""
$serverLabel = ""
$devopsServerLabel = "DevOps Server"
$prodServerLabel = "Production Server"
$uatServerLabel = "UAT Server"
$input = ""
$repoBranch = $branchName

# Procesar argumentos
param(
    [Parameter(Mandatory=$false)]
    [string]$branchName
)

if ($args -contains "--help") {
    Write-Host ""
    Write-Host "  Uso: .\install.ps1 [-branchName <branch/name>]"
    Write-Host ""
    Write-Host "  -branchName:   Nombre de la rama que se quiere ejecutar."
    Write-Host ""
    exit
}

$remoteRepo = "https://raw.githubusercontent.com/MartinSIbarra/free-hosting-with-local-architecture/refs/heads/$repoBranch/assets"

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
    if ($input -notin 1,2,3) {
        Write-Host "`n  0) Salir"
        Write-Host "`n  Selecciona una opción (1-3) o 0 para salir:"
    }
}

while ($showMenu) {
    Show-Menu
    $input = Read-Host

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

    if ($input -in 1,2,3) {
        Write-Host "`n  Has elegido la opción $input - $serverLabel"

        if (Test-Path "$serverPath\Vagrantfile") {
            Write-Host "`n  Ya existe la máquina virtual para esta opcion, no se puede crear."
            Write-Host "  Presiona cualquier tecla para volver al menú."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        } else {
            if ($input -eq 1) {
                $ngrokAuthToken = Read-Host "  - Ingresar token para ngrok"
                if ($ngrokAuthToken) {
                    $ngrokTunnelUrl = Read-Host "  - Ingresar url para ngrok"
                    if (-not $ngrokTunnelUrl) {
                        $input = ""
                        continue
                    }
                }
            }
            if ($input) {
                Write-Host "`n  Presiona Enter para confirmar ó ESC para volver al menú."
                $confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                if ($confirm.VirtualKeyCode -eq 13) { # Enter
                    $option = $input
                    $showMenu = $false
                } elseif ($confirm.VirtualKeyCode -eq 27) { # ESC
                    $input = ""
                }
            }
        }
    }
}

if (-not (Test-Path $serverPath)) {
    New-Item -ItemType Directory -Path $serverPath | Out-Null
}
Set-Location $serverPath

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

Execute-Command "Invoke-WebRequest -Uri $remoteRepo/Vagrantfile -OutFile Vagrantfile"

# Reemplazar variables en el Vagrantfile
(Get-Content Vagrantfile) -replace 'repo_branch = "main"', "repo_branch = `"$repoBranch`"" |
    Set-Content Vagrantfile
(Get-Content Vagrantfile) -replace 'ngrok_auth_token: ""', "ngrok_auth_token: `"$ngrokAuthToken`"" |
    Set-Content Vagrantfile
(Get-Content Vagrantfile) -replace 'ngrok_tunnel_url: ""', "ngrok_tunnel_url: `"$ngrokTunnelUrl`"" |
    Set-Content Vagrantfile

Write-Host "  Instalando $serverLabel..."
Write-Host ""
Invoke-Expression "vagrant up"
Invoke-Expression "vagrant reload --provision-with post1,post2,post3"
# ...existing code...