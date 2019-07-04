param(
    [String]$Hostname = "win10",
    [String]$Username = "chantal",
    [String]$Password = "wololo",
    [Int]$ResX = 1920,
    [Int]$ResY = 1080
)

$ScriptDir = Split-Path $MyInvocation.InvocationName

Start-Transcript "${ScriptDir}\stage1.log"

# Kill Windows Update and make sure it stays dead
Write-Host "Getting rid of Windows Update."
Stop-Service wuauserv
Set-Service wuauserv -StartupType Disabled

# Disable autostart stuff
Write-Host "Disabling BGInfo."
Remove-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name *

# User
Write-Host "Creating user '${Username}' with password '${Password}'."
$SecurePassword = ConvertTo-SecureString -String "${Password}" -AsPlainText -Force
New-LocalUser -Name "${Username}" -Password $SecurePassword | Out-Null
Add-LocalGroupMember -Group Administrators -Member "${Username}"
Disable-LocalUser IEUser

Write-Host "Setting up automatic login for '${Username}'."
Set-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" DefaultPassword "${Password}"
Set-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" DefaultUserName "${Username}"

# Reconfigure OpenSSHd
Write-Host "Setting up SSH access."
$SID = Get-LocalUser $Username | select -ExpandProperty SID
$PasswdLine = "${Username}:*:197612:197121:U-${Hostname}\${Username},${SID}:/cygdrive/c/Users/${Username}:/bin/sh"
Push-Location "${env:programfiles}\OpenSSH\etc"
Add-Content -Path .\passwd "${PasswdLine}"
Remove-Item ssh_host*
Copy-Item "${ScriptDir}\ssh_host_*" .
Pop-Location

# Firewall
Write-Host "Setting up RDP access."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0
Enable-NetFirewallRule -Name RemoteDesktop-UserMode-In-UDP
Enable-NetFirewallRule -Name RemoteDesktop-UserMode-In-TCP

# Install virtio storage driver
Write-Host "Installing virtio storage drivers."
# Thanks to https://stackoverflow.com/questions/36775331/extract-certificate-from-sys-file
$InfFile = "D:\viostor\w10\amd64\viostor.inf"
$SysFile = "D:\viostor\w10\amd64\viostor.sys"
$CerFile = "${ScriptDir}\RedHat.cer"
$ExportType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
$Cert = (Get-AuthenticodeSignature $SysFile).SignerCertificate
[System.IO.File]::WriteAllBytes($CerFile, $Cert.Export($ExportType))
Import-Certificate -FilePath "$CerFile" -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null
Start-Process $InfFile -Verb Install
Start-Sleep 5

# Initialize virtio dummy disk, so that virtio will work for the boot drive
Write-Host "Preparing virtio storage drivers for boot."
Get-Disk | ?{ $_.PartitionStyle -eq "RAW" } | `
    Initialize-Disk -PartitionStyle MBR -PassThru | `
    New-Partition -AssignDriveLetter -UseMaximumSize | `
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "dummy" -Confirm:$false | Out-Null

# Display resolution
Write-Host "Setting display resolution to ${ResX}x${ResY}."
Push-Location "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration\MSBDD_NOEDID_1234_1111_00000000_00010000_0^FD62006E2425EAA7C207AF2974F7309B\00"
Set-ItemProperty -Path .  -Name PrimSurfSize.cx   -Value $ResX
Set-ItemProperty -Path .  -Name PrimSurfSize.cy   -Value $ResY
Set-ItemProperty -Path .  -Name Stride            -Value $(4 * $ResX)
Set-ItemProperty -Path 00 -Name PrimSurfSize.cx   -Value $ResX
Set-ItemProperty -Path 00 -Name PrimSurfSize.cy   -Value $ResY
Set-ItemProperty -Path 00 -Name Stride            -Value $(4 * $ResX)
Set-ItemProperty -Path 00 -Name ActiveSize.cx     -Value $ResX
Set-ItemProperty -Path 00 -Name ActiveSize.cy     -Value $ResY
Set-ItemProperty -Path 00 -Name DwmClipBox.right  -Value $ResX
Set-ItemProperty -Path 00 -Name DwmClipBox.bottom -Value $ResY
Set-ItemProperty -Path 00 -Name Flags             -Value 0x830f8f
Pop-Location

# Hostname
Write-Host "Changing hostname to '${Hostname}'."
Rename-Computer -NewName "${Hostname}" | Out-Null

# Shutdown
Write-Host "Shutting VM down."
Start-Process -NoNewWindow "shutdown.exe" -ArgumentList "/s /t 0"

Stop-Transcript
