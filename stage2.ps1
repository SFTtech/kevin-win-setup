# Import BITS for file transfers
#Import-Module BitsTransfer

# IMPORTANT NOTE!
# Need to set the following command manually, to run this script on a standard Win10 machine
# don't close the Powershell afterwards because for security reasons scripts are just allowed
# for the current powershell process
# >>> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# Dependencies to be downloaded
# GitHub-Files can be referenced with their RepoName and the Flag "isGit"
# that will Download automatically the newest Release-Version
# Search for #ADD NEW SOFTWARE LINK GENERATION HERE and add a new case for the Link generation
$deps = @(
#    [PSCustomObject]@{Name = "cmake"; isGit=$true; isZip=$true; isInstaller=$false; isConfig=$false; LatestRelease =""; RepoName = "Kitware/CMake"; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""}
    [PSCustomObject]@{Name = "mingit"; isGit=$true; isZip=$true; isInstaller=$false; isConfig=$false; LatestRelease = ""; RepoName = "git-for-windows/git"; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""}
#    [PSCustomObject]@{Name = "flex"; isGit=$true; isZip=$true; isInstaller=$false; isConfig=$false; LatestRelease =""; RepoName = "lexxmark/winflexbison"; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""}
#    [PSCustomObject]@{Name = "python3"; isGit=$false; isZip=$false; isInstaller=$true; isConfig=$false; LatestRelease = ""; RepoName = ""; DownloadLink = "https://www.python.org/ftp/python/3.7.3/python-3.7.3-amd64.exe"; HashFile = ""; HomeDir = ""; FileName = ""}
#    [PSCustomObject]@{Name = "vs_buildtools"; isGit=$false; isZip=$false; isInstaller=$true; isConfig=$false; LatestRelease = ""; RepoName = ""; DownloadLink = "https://download.visualstudio.microsoft.com/download/pr/10413969-2070-40ea-a0ca-30f10ec01d1d/414d8e358a8c44dc56cdac752576b402/vs_buildtools.exe"; HashFile = ""; HomeDir = ""; FileName = ""; ConfigPath=""}
#    [PSCustomObject]@{Name = "vs_buildtools\config"; LinkName="vs_buildtools"; isGit=$false; isZip=$false; isInstaller=$false; isConfig=$true; LatestRelease = ""; RepoName = ""; DownloadLink = "https://raw.githubusercontent.com/simonsan/kevin-win-setup/stage2/vsconfig/build_tools.vsconfig"; HashFile = ""; HomeDir = ""; FileName = ""}
#    [PSCustomObject]@{Name = "nsis"; LinkName=""; isGit=$false; isZip=$false; isInstaller=$false; isConfig=$false; LatestRelease = ""; RepoName = ""; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""}
  
   # Preset New Download (Search for #ADD NEW SOFTWARE LINK GENERATION HERE and add a new case)
   # [PSCustomObject]@{Name = ""; isGit=""; RepoName = ""; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""} 
)

$bin = @(
        [PSCustomObject]@{Name="cmake"; BinDir=""; BinPath="\bin\cmake.exe"}
        [PSCustomObject]@{Name="mingit"; BinDir=""; BinPath="\cmd\git.exe"}
        [PSCustomObject]@{Name="flex"; BinDir=""; BinPath="\win_flex.exe"}
#        [PSCustomObject]@{Name="pip"; BinDir=""; BinPath=""}
#        [PSCustomObject]@{Name="python3"; BinDir=""; BinPath=""}
#        [PSCustomObject]@{Name="vcpkg"; BinDir=""; BinPath=""}
#        [PSCustomObject]@{Name="cpack"; BinDir=""; BinPath=""\bin\cpack.exe""}
)

# Command to install the dependencies from pip
$pip_command="install cython numpy pillow pygments pyreadline Jinja2"

# Command to install the dependencies from vcpkg
$vcpkg_x64_command="install dirent eigen3 fontconfig freetype harfbuzz libepoxy libogg libpng opus opusfile qt5-base qt5-declarative qt5-quickcontrols sdl2 sdl2-image --triplet x64-windows"

# Change to preferred download path
$dependency_dl_path="$env:HOMEDRIVE\openage-dl\";


# Flag for DRY RUN -> TODO
#$dry_run=false;


# Function to create folderstructure
Function GenerateFolders($path){
    $global:foldPath=$null
    
    foreach($foldername in $path.split("\")){
          $global:foldPath+=($foldername+"\")

          if(!(Test-Path $global:foldPath)){
              New-Item -ItemType Directory -Path $global:foldPath
              Write-Host "$global:foldPath Folder created successfully!"
          }elseif((Test-Path $global:foldPath)){
              Write-Host "$global:foldPath Folder already exists!"
          }
#elseif($dry_run){
#            Write-Host "DRYRUN: $global:foldPath folder was not created!"
#          }
    }   
}

# Create subfolder for each dependency and save in $deps
Function GenerateDepFolders{
    Param($arr, [string]$path)

        $arr | ForEach-Object { 
            GenerateFolders "$($path)$($_.Name)"
            $_.HomeDir = "$($path)$($_.Name)\"
        }    
    
}

# Function to download dependency setups
# TODO Do not redownload already installed/downloaded deps
# TODO Find a way to cache actual version number in a environment variable/text file
Function DownloadDependencies($arr){

     Write-Host "Downloading dependencies ..."
    
     $arr | ForEach-Object {
            # Start-BitsTransfer -Source $_.HashFile -Destination $_.HomeDir -Asynchronous
            $source = "$($_.DownloadLink)"
            $output = "$($_.HomeDir)$($_.FileName)"

            # Don't download if file already there
            if( !(Test-Path $output)){
           
                Write-Host "Downloading $($_.Name) ..."
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            
                if(($_.Name) -eq "vs_buildtools"){

                     # Visual Studio 17 CE (advanced options) - Build tools
              
                     $job = Invoke-WebRequest -Uri $source  -OutFile $output -Headers @{"method"="GET"; "authority"="download.visualstudio.microsoft.com"; "scheme"="https"; "path"="/download/pr/10413969-2070-40ea-a0ca-30f10ec01d1d/414d8e358a8c44dc56cdac752576b402/vs_buildtools.exe"; "upgrade-insecure-requests"="1"; "dnt"="1"; "user-agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36"; "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3"; "referer"="https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=BuildTools&rel=15"; "accept-encoding"="gzip, deflate, br"; "accept-language"="en-US,en;q=0.9"}
                 

                }else{
                     # Other dependencies besides VS-Buildtools.exe
                     # But gets config-files for the vs-installer as well
                     $job = Invoke-WebRequest -Uri $source -OutFile $output
                                    
                }

                While ($job.JobState -eq "Transferring") {
                         Sleep -Seconds 3
                }

    
            }elseif(Test-Path $output){
           
              Write-Host "$output already exists! Continuing with already existing file."
    
            }

    }

}

# Function to generate FileName and FilePath from DownloadLink
Function GenerateFileNames($arr){

    Write-Host "Generating Filenames ..."

    $arr | ForEach-Object {
           $_.FileName = "$($_.DownloadLink.SubString($_.DownloadLink.LastIndexOf('/') + 1))"
          
           # Debug
           Write-Host $_.HomeDir
           Write-Host $_.FileName
    }
}

# Get the link for the latest version of a github repo
# Inspired by https://gist.github.com/f3l3gy/0e89dde158dde024959e36e915abf6bd
Function GetLatestVersionLink($arr){
    
    Write-Host "Get the latest version of Github-Releases ..."

    $arr | ForEach-Object {

           # Github
           if(($_.isGit) -eq $true){
               $releases = "https://api.github.com/repos/$($_.RepoName)/releases"
           
               Write-Host "Determining latest release for $($_.Name)"
               [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
           
               $versionRequest = ((ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri  $releases -UseBasicParsing)) | Where {$_.prerelease -eq $false})[0]

               $_.LatestRelease = $versionRequest[0].tag_name
         
               #$_.DownloadLink = ($versionRequest | Where {$_.content_type -eq "application/zip"})
           

               #ADD NEW SOFTWARE LINK GENERATION HERE
               # >>>
          
               if(($_.Name) -eq "mingit"){
                   #MinGit-2.21.0-64-bit.zip
                   $name = "$($_.Name)-"
                   $version=($_.LatestRelease.Substring(1))
                   $version= $version.Substring(0,$version.Length-10)
                   $arch="-64-bit"
                   $type=".zip"

               }elseif(($_.Name) -eq "cmake"){
                   #cmake-3.14.5-win64-x64.zip 
                   $name = "$($_.Name)-"  
                   $version=$_.LatestRelease.Split("v")[1]
                   $arch="-win64-x64"
                   $type=".zip"
           
               }elseif(($_.Name) -eq "flex"){
                   #win_flex_bison-2.5.18.zip 
                   $name = "win_$($_.Name)_bison-"  
                   $version=$_.LatestRelease.Split("v")[1]
                   $arch=""
                   $type=".zip"
           
               
               }

               $file="$name$version$arch$type"

               #ADD NEW SOFTWARE LINK GENERATION HERE
               # >>> <<<
               
               
               Write-Host "The latest release of $($_.Name) is $($_.LatestRelease)."

               # Debug
               # Write-Host "DownloadLink for $($_.RepoName) is"
               
               $_.DownloadLink="https://github.com/$($_.RepoName)/releases/download/$($_.LatestRelease)/$($file)"
               
               # Debug
               # Write-Host $_.DownloadLink

 

          }

    }
   
}

# Extract Zip-Files and delete archives afterwards
# Sets the HomeDir to the extracted new Folder structure
Function ExtractDependencies{
    Param($arr, [string]$path)

    $arr | ForEach-Object {
    
        if(($_.isZip) -eq $true){
            
            Set-Location -Path $_.HomeDir
          
            $zip = "$($_.HomeDir)$($_.FileName)"

            if(!(Test-Path($zip.Substring(0,$zip.Length-4)))){
                
                if(($_.Name) -eq "flex"){
                    $folder = ($zip.Substring(0,$zip.Length-4))
                    GenerateFolders $folder
                    $_.HomeDir = $folder
                                
                }elseif(($_.Name) -eq "mingit"){
                    $folder = ($zip.Substring(0,$zip.Length-4))
                    GenerateFolders $folder
                    $_.HomeDir = $folder
                                
                } 
                
                Write-Host "Extracting $($_.Name) files"
                Expand-Archive -LiteralPath $zip -DestinationPath $_.HomeDir -Force
               
                # TODO Archiv muss zum Testen nicht gelöscht werden!
                # Remove-Item  $zip  -Force

                $_.HomeDir = $zip.Substring(0,$zip.Length-4)
            } else {
                Write-Host "Extracted version is already existing! Continuing without extraction!"
                $_.HomeDir = $zip.Substring(0,$zip.Length-4)
            }

            Set-Location -Path $path

            # Debug
            # Write-Host $_.HomeDir 

        }
        
    }

}

# Connect a downloaded config file to a setup
Function ConnectConfig($arr){

   Write-Host "Connecting Configs ..."
    
   $arr | ForEach-Object {
          if(($_.isConfig) -eq $true){
          
            # LinkName should not be empty
            if($_.LinkName){
                
               $linkname_temp = $_.LinkName
               $cfg_path_temp = "$($_.HomeDir)$($_.FileName)"
                
               $change = ($arr | Where {$($_.Name) -eq $($linkname_temp)})  
               $change.ConfigPath = $cfg_path_temp

            }
          }
    
    }

 }
 
# Install the dependencies
# TODO Testing
Function InstallDependencies($arr){



    $arr | ForEach-Object {
         if(($_.isInstaller) -eq $true){


           if(($_.Name) -eq "python3"){

             # Installer Routine for Python
             Write-Host "Installing $($_.Name), this can take a longer time. Do not close this window!"

             $setup = Start-Process "$($_.HomeDir)$($_.FileName)" -ArgumentList "/s /passive Include_debug=1 Include_dev=1 Include_lib=1 Include_pip=1 PrependPath=1 CompileAll=1 InstallAllUsers=1 TargetDir=$($_.HomeDir)" -Wait
             if ($setup.exitcode -eq 0){
                write-host "$($_.Name) installed succesfully."
             }
           }elseif(($_.Name) -eq "vs_buildtools"){

             # Installer Routine for VS Buildtools
             Write-Host "Installing $($_.Name), this can take a longer time. Do not close this window!"
             $setup = Start-Process "$($_.HomeDir)$($_.FileName)" -ArgumentList "-p --addProductLang En-us --norestart --noUpdateInstaller --downloadThenInstall --force --config $($_.ConfigPath)" -Wait

             if ($setup.exitcode -eq 0){
                write-host "$($_.Name) installed succesfully."
             }
           }
         


         }


    }

}


# Get direktlink to binary
Function GetBinaryLinks($arr){

  
     $arr | ForEach-Object {
               $name_temp = $_.Name
               $home_dir_temp = $_.HomeDir  
                
               $change = ($bin | Where {$($_.Name) -eq $($name_temp)})  
             
               $change.BinDir = $home_dir_temp
               $change.BinPath = "$($home_dir_temp)$($change.BinPath)"

     }

}

# Git Clone imitating
Function GitClone([string]$address,[string]$path){

    # Git Binary
    $git = ($bin | Where {$($_.Name) -eq $("mingit")} | Select BinPath)

    GenerateFolders $path
    Set-Location -Path $path

    Start-Process -FilePath $git.BinPath -ArgumentList "clone $($address)" -Wait

}



## Main

# Create Directory for dependency downloads
GenerateDepFolders -arr $deps -path $dependency_dl_path

# Get Latest from Github
GetLatestVersionLink $deps

# Generate FileNames from Link
GenerateFileNames $deps

# Download all Dependencies
DownloadDependencies $deps

# Extract Dependencies
ExtractDependencies -arr $deps -path $dependency_dl_path

# Link config files
ConnectConfig $deps

# Install Dependencies
#InstallDependencies $deps

# Get Links to Binaries
GetBinaryLinks $deps

# Get into functions

# vcpkg
# Write-Host "Please wait, while we are cloning vcpkg"
# GitClone -address "https://github.com/Microsoft/vcpkg.git" -path $dependency_dl_path
# Set-Location -Path "$($dependency_dl_path)vcpkg"
# & .\bootstrap-vcpkg.bat

# Adding to $bin
# $bin.Add("vcpkg","$($dependency_dl_path)vcpkg","$($dependency_dl_path)vcpkg\vcpkg.exe")


# $vcpkg integrate install
# $vcpkg install XXX

# Python should be in PATH from here
# -> PIP
# git and cmake still missing in PATH


# Ready
Write-Host "Here we are ready."

# Cleanup
# CleanUp $deps

# Notes


# Set Environment variables
# Install paths
# VCPKG_DEFAULT_TRIPLET=x64-windows
# cmake
# git
# Python (automatically)
# PATH: Flex
# Buildtools: C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools

# Alternative to Invoke-Webrequest
# Start-BitsTransfer -Source $_.HashFile -Destination $_.HomeDir -Asynchronous
# Start-BitsTransfer -Source $_.DownloadLink -Destination $_.HomeDir -Asynchronous -DisplayName "Downloading $_.Name ..." 


# Version caching in Umgebungsvariable oder ähnlichem

# pip install modules

# Prereq. MSVC17
# clone vcpkg and build to higher directory (e.g. C:\)
# vcpkg integrate, build and install packages
# 

# TODO Verification
# pgp for windows
# sha256