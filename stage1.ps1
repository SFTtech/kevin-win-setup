param(
    [String]$Hostname = "win10",
    [String]$Username = "chantal",
    [String]$Password = "Passw0rd!"
)

$ScriptDir = Split-Path $MyInvocation.InvocationName

Start-Transcript "${ScriptDir}\stage1.log"

# Kill Windows Update and make sure it stays dead
Stop-Service wuauserv
Set-Service wuauserv -StartupType Disabled

# Change hostname and user
Rename-Computer -NewName "${Hostname}"
$SecurePassword = ConvertTo-SecureString -String "${Password}" -AsPlainText -Force
New-LocalUser -Name "${Username}" -Password $SecurePassword
Add-LocalGroupMember -Group Administrators -Member "${Username}"
Disable-LocalUser IEUser
Set-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" DefaultPassword "${Password}"
Set-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" DefaultUserName "${Username}"

# Reconfigure OpenSSHd
$SID = Get-LocalUser $Username | select -ExpandProperty SID
$PasswdLine = "${Username}:*:197612:197121:U-${Hostname}\${Username},${SID}:/cygdrive/c/Users/${Username}:/bin/sh"

Push-Location "${env:programfiles}\OpenSSH\etc"
Add-Content -Path .\passwd "${PasswdLine}"
Remove-Item ssh_host*
Copy-Item "${ScriptDir}\ssh_host_*" .
Pop-Location

# Install virtio storage driver
# Thanks to https://stackoverflow.com/questions/36775331/extract-certificate-from-sys-file
$InfFile = "D:\viostor\w10\amd64\viostor.inf"
$SysFile = "D:\viostor\w10\amd64\viostor.sys"
$CerFile = "${ScriptDir}\RedHat.cer"
$ExportType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
$Cert = (Get-AuthenticodeSignature $SysFile).SignerCertificate
[System.IO.File]::WriteAllBytes($CerFile, $Cert.Export($ExportType))
Import-Certificate -FilePath "$CerFile" -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
Start-Process $InfFile -Verb Install
Start-Sleep 5

# Initialize virtio dummy disk, so that virtio will work for the boot drive
Get-Disk | ?{ $_.PartitionStyle -eq "RAW" } | `
    Initialize-Disk -PartitionStyle MBR -PassThru | `
    New-Partition -AssignDriveLetter -UseMaximumSize | `
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "dummy" -Confirm:$false

# We are done.
Start-Process -NoNewWindow "shutdown.exe" -ArgumentList "/s /t 0"
Stop-Transcript
