#redirigimos el script a ventana de administrador
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
    exit;
}

#generamos exclusion windows defender para poder trabajar con los bats
$download_folder = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
Add-MpPreference -ExclusionPath "$download_folder"

# PLANTILLA
# $program = "www.cloudbox.altia.example/download"
# $program_file = "C:\Users\Public\Downloads\installer.exe"
# Invoke-WebRequest -Uri $program -OutFile $program_file
# Start-Process -Filepath "C:\Users\Public\Downloads\intaller.exe" -ArgumentList $args

#definimos los enlaces de descarga y las rutas (enlace al .exe directamente acabado en /download)
$ninite = "https://cloudbox.altia.es/index.php/s/QzJ9ApJytbNwZXR/download" #chrome-filezilla-firefox-gimp-greenshot-pidgin-putty-thunderbird-7zip-zoom
$ninite_file = "$download_folder\instalador_temp_ninite.exe"
$anydesk = "https://cloudbox.altia.es/index.php/s/DxYYQpL6mScJwba/download"
$anydesk_file = "$download_folder\instalador_temp_anydesk.msi" #silent install
$chrome = "https://cloudbox.altia.es/index.php/s/PbgLQd6gap4zo92/download"
$chrome_file = "$download_folder\instalador_temp_chrome.exe"
$filezilla = "https://cloudbox.altia.es/index.php/s/EdKPeGsze3ZzxDc/download"
$filezilla_file = "$download_folder\instalador_temp_filezilla.exe"
$firefox = "https://cloudbox.altia.es/index.php/s/RjX7YjXiEK4PGKy/download"
$firefox_file = "$download_folder\instalador_temp_firefox.msi" #silent install
$acrobatreader = "https://cloudbox.altia.es/index.php/s/pQMcZWHjJ4TnFrE/download"
$acrobatreader_file = "$download_folder\readerdc_es_a_install.exe"
$gimp = "https://cloudbox.altia.es/index.php/s/LkAy2pYQtS4YtKD/download"
$gimp_file = "$download_folder\instalador_temp_gimp.exe"
$greenshot = "https://cloudbox.altia.es/index.php/s/qSqjBMJdNzbD6PE/download"
$greenshot_file = "$download_folder\instalador_temp_greenshot.exe"
$libreoffice = "https://cloudbox.altia.es/index.php/s/8sLpGf7Mqr9Jmrc/download" # 6.4.6 stable
$libreoffice_file = "$download_folder\instalador_temp_libreoffice.msi"
$nextcloud = "https://cloudbox.altia.es/index.php/s/mojcF87DWQajzDf/download"
$nextcloud_file = "$download_folder\instalador_temp_nextcloud.exe"
$ocs = "https://cloudbox.altia.es/index.php/s/t7NzDZPfFramYFz/download"
$ocs_file = "$download_folder\instalador_temp_ocs.bat" #bat necesita chrome como navegador por defecto
$openvpn = "https://cloudbox.altia.es/index.php/s/jYiwdW7S9XtbwbT/download"
$openvpn_file = "$download_folder\instalador_temp_openvpn.msi"
$pidgin = "https://cloudbox.altia.es/index.php/s/xaBKYCYgoXozfnE/download"
$pidgin_file = "$download_folder\instalador_temp_pidgin.exe"
$putty = "https://cloudbox.altia.es/index.php/s/RGPJmKEgRMfnFRo/download"
$putty_file = "$download_folder\instalador_temp_putty.msi" #silent install (?)
$rocket = "https://cloudbox.altia.es/index.php/s/WpFWezz78TW3ciH/download"
$rocket_file = "$download_folder\instalador_temp_rocket.exe"
$thunderbird = "https://cloudbox.altia.es/index.php/s/KGTiPz5JdsWjdZ6/download"
$thunderbird_file = "$download_folder\instalador_temp_thunderbird.msi" #silent install (?)
$7zip = "https://cloudbox.altia.es/index.php/s/yE9LRm2Xof2sF3J/download"
$7zip_file = "$download_folder\instalador_temp_winrar.exe"
$zoom = "https://cloudbox.altia.es/index.php/s/R3zwrH53qFKf2xb/download"
$zoom_file = "$download_folder\instalador_temp_zoom.exe"

#empezamos descarga y ejecucion de ninite asi descargan el resto en segundo plano mientras instalamos
Invoke-WebRequest -Uri $ninite -OutFile $ninite_file
Write-Output "Instalador de Ninite descargado!"
$confirmacion = ""
 do{
    $confirmacion = Read-Host "Vamos a instalar Ninite, continuar?"
    if ($confirmacion -eq "y") {
        Start-Process -Filepath $ninite_file
    } elseif ($confirmacion -eq "n") {
        Write-Output "Ninite no instalado."
    } else {
        Write-Output "opcion no valida, elige y/n"
    }
 } while ($confirmacion -ne "y" -and $confirmacion -ne "n")

#descarga de .exes
Invoke-WebRequest -Uri $anydesk -OutFile $anydesk_file
Write-Output "Instalador de AnyDesk descargado!"
Invoke-WebRequest -Uri $acrobatreader -OutFile $acrobatreader_file
Write-Output "Instalador de Acrobat Reader descargado!"
#Invoke-WebRequest -Uri $chrome -OutFile $chrome_file
#Write-Output "Instalador de Google Chrome descargado!"
#Invoke-WebRequest -Uri $filezilla -OutFile $filezilla_file
#Write-Output "Instalador de FileZilla descargado!"
#Invoke-WebRequest -Uri $firefox -OutFile $firefox_file
#Write-Output "Instalador de Firefox descargado!"
#Invoke-WebRequest -Uri $foxit -OutFile $foxit_file
#Write-Output "Instalador de Foxit PDF Reader descargado!"
#Invoke-WebRequest -Uri $gimp -OutFile $gimp_file
#Write-Output "Instalador de GIMP descargado!"
#Invoke-WebRequest -Uri $greenshot -OutFile $greenshot_file
#Write-Output "Instalador de Greenshot descargado!"
Invoke-WebRequest -Uri $libreoffice -OutFile $libreoffice_file
Write-Output "Instalador de LibreOffice descargado!"
Invoke-WebRequest -Uri $nextcloud -OutFile $nextcloud_file
Write-Output "Instalador de NextCloud descargado!"
Invoke-WebRequest -Uri $ocs -OutFile $ocs_file
Write-Output "Instalador de OCS descargado!"
Invoke-WebRequest -Uri $openvpn -OutFile $openvpn_file
Write-Output "Instalador de OpenVPN descargado!"
#Invoke-WebRequest -Uri $pidgin -OutFile $pidgin_file
#Write-Output "Instalador de Pidgin descargado!"
#Invoke-WebRequest -Uri $putty -OutFile $putty_file
#Write-Output "Instalador de Putty descargado!"
Invoke-WebRequest -Uri $rocket -OutFile $rocket_file
Write-Output "Instalador de Rocket Chat descargado!"
#Invoke-WebRequest -Uri $thunderbird -OutFile $thunderbird_file
#Write-Output "Instalador de Thunderbird descargado!"
#Invoke-WebRequest -Uri $winrar -OutFile $winrar_file
#Write-Output "Instalador de WinRar descargado!"
#Invoke-WebRequest -Uri $zoom -OutFile $zoom_file
#Write-Output "Instalador de Zoom descargado!"

#ejecucion
$cosasAInstalar = @($anydesk_file, $openvpn_file, $rocket_file, $nextcloud_file, $libreoffice_file, $acrobatreader_file)
foreach ($instalador in $cosasAInstalar) {
    $confirmacion = ""
    do{
        $confirmacion = Read-Host "Vamos a instalar $instalador, continuar?"
        if ($confirmacion -eq "y") {
            Start-Process -Filepath $instalador
            Write-Output "Iniciando..."
        } elseif ($confirmacion -eq "n") {
            Write-Output "$instalador no instalado."
        } else {
            Write-Output "opcion no valida, elige y/n"
        }
    } while ($confirmacion -ne "y" -and $confirmacion -ne "n")
}

#eliminamos los instaladores
$confirmacion = ""
do{
    $confirmacion = Read-Host "Instalacion finalizada, eliminar instaladores?"
    if ($confirmacion -eq "y") {
        Start-Sleep -s 2
        Remove-Item $cosasAInstalar
        $download_folder = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
    } elseif ($confirmacion -eq "n") {
        Write-Output "Los instaladores estan en $download_folder , eliminalos al acabar."
    } else {
        Write-Output "opcion no valida, elige y/n"
    }
} while ($confirmacion -ne "y" -and $confirmacion -ne "n")

Read-Host -Prompt "Cuando hayas acabado de instalar, vamos a añadir el equipo al dominio."
#eliminamos exclusion windows defender
Remove-MpPreference -ExclusionPath "C:\Users\Public\Downloads"

### Copiado de UnirAdominio.ps1
### CAMBIA EL FONDO DEL EQUIPO

$setwallpapersrc = @"
using System.Runtime.InteropServices;
public class wallpaper
{
public const int SetDesktopWallpaper = 20;
public const int UpdateIniFile = 0x01;
public const int SendWinIniChange = 0x02;
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
public static void SetWallpaper ( string path )
{
SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
}
}
"@
Add-Type -TypeDefinition $setwallpapersrc
[wallpaper]::SetWallpaper("E:\TOOLS\Preparar Equipo\dependencias\fondo.bmp")

### CAMBIA LA DNS DEL EQUIPO

Set-DNSClientServerAddress -InterfaceIndex (Get-NetAdapter).InterfaceIndex -ServerAddresses 192.168.0.24,8.8.8.8

### CAMBIA EL NOMBRE DEL EQUIPO Y LO CONECTA AL DOMINIO

$computername = read-host "Nuevo nombre para el equipo"
$cred = get-credential
Rename-Computer -NewName $computername
Start-Sleep 5
add-computer -DomainName altia -Credential $cred -Options JoinWithNewName,AccountCreate
pause

$cosasAInstalar = @($ocs_file)
foreach ($instalador in $cosasAInstalar) {
    $confirmacion = ""
    do{
        $confirmacion = Read-Host "Vamos a instalar $instalador, continuar?"
        if ($confirmacion -eq "y") {
            Start-Process -Filepath $instalador
            Write-Output "Iniciando..."
        } elseif ($confirmacion -eq "n") {
            Write-Output "$instalador no instalado."
        } else {
            Write-Output "opcion no valida, elige y/n"
        }
    } while ($confirmacion -ne "y" -and $confirmacion -ne "n")
}

#el script se elimina a si mismo
Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force
