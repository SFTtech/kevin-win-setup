# Import BITS for file transfers
# Import-Module BitsTransfer

# TODO Move out everything which could be an extra configuration of openage building
# e.g. 32bit MSVC 2019 or 64bit MSVC 2017
# a bit like a "Desired State Configuration" for dependencies
# DSC-stable.json should have one big configuration of
# Array/Hash-Table->$dep
# Folder-Configs
# Architecture
# Compiler version
# standard/binary paths with BinDir = $dep_dl_path + $binary_name


# IMPORTANT NOTE!
# Need to set the following command manually, to run this script on a standard Win10 machine
# don't close the Powershell afterwards because for security reasons scripts are just allowed
# for the current powershell process
# >>> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# Change to preferred download path
$dependency_dl_path="$env:HOMEDRIVE\openage-dl\";

# 32/64 bit
# TODO Set flag where version exchange can be possible
$is64bit=$true

# User hardcoded version file
# TODO Write importer function
# $hardcoded_version_file="stable.json"

# Change Build-Directory
$build_dir="$env:HOMEDRIVE\openage-build\";

# Python-DL
# TODO How to automate version DL?
$python_dl="https://www.python.org/ftp/python/3.7.3/python-3.7.3-amd64.exe"

# Path vcpkg should be in
$vcpkg_path="$($dependency_dl_path)vcpkg\"

# cmake commad
if($is64bit){
   # $build_arch = "Win64"
   Write-Host "64bit Flag activated! Everything will be downloaded and build in 64bit/x64 architecture!"
}else{
   # $build_arch = "Win32"
   Write-Host "32bit Flag activated! Everything will be downloaded and build in 32bit/x86 architecture!"
}

# cmake Visual Studio version
$build_vs_ver = "Visual Studio 15 2017"

# Dependencies to be downloaded
# GitHub-Files can be referenced with their RepoName and the Flag "isGit"
# that will Download automatically the newest Release-Version
# Search for #ADD NEW SOFTWARE LINK GENERATION HERE and add a new case for the Link generation
$deps = @(
    [PSCustomObject]@{Name = "cmake"; isGit=$true; isZip=$true; isInstaller=$false; isConfig=$false; LatestRelease =""; RepoName = "Kitware/CMake"; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""}
    [PSCustomObject]@{Name = "mingit"; isGit=$true; isZip=$true; isInstaller=$false; isConfig=$false; LatestRelease = ""; RepoName = "git-for-windows/git"; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""}
    [PSCustomObject]@{Name = "flex"; isGit=$true; isZip=$true; isInstaller=$false; isConfig=$false; LatestRelease =""; RepoName = "lexxmark/winflexbison"; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""}
    [PSCustomObject]@{Name = "python3"; isGit=$false; isZip=$false; isInstaller=$true; isConfig=$false; LatestRelease = ""; RepoName = ""; DownloadLink = $python_dl; HashFile = ""; HomeDir = ""; FileName = ""}
    [PSCustomObject]@{Name = "vs_buildtools"; isGit=$false; isZip=$false; isInstaller=$true; isConfig=$false; LatestRelease = ""; RepoName = ""; DownloadLink = "https://download.visualstudio.microsoft.com/download/pr/10413969-2070-40ea-a0ca-30f10ec01d1d/414d8e358a8c44dc56cdac752576b402/vs_buildtools.exe"; HashFile = ""; HomeDir = ""; FileName = ""; ConfigPath=""}
    [PSCustomObject]@{Name = "vs_buildtools\config"; LinkName="vs_buildtools"; isGit=$false; isZip=$false; isInstaller=$false; isConfig=$true; LatestRelease = ""; RepoName = ""; DownloadLink = "https://raw.githubusercontent.com/simonsan/kevin-win-setup/stage2/vsconfig/build_tools.vsconfig"; HashFile = ""; HomeDir = ""; FileName = ""}
#   [PSCustomObject]@{Name = "nsis"; LinkName=""; isGit=$false; isZip=$false; isInstaller=$false; isConfig=$false; LatestRelease = ""; RepoName = ""; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""}
#   TODO: Font-Download  
   # Preset New Download (Search for #ADD NEW SOFTWARE LINK GENERATION HERE and add a new case)
   # [PSCustomObject]@{Name = ""; isGit=""; RepoName = ""; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""} 
)

# TODO Move $deps to json file
# Always import from there
#$deps | ConvertTo-Json -depth 100 | Out-File "$($dependency_dl_path)latest2.json"

# From JSON 
#$deps_import = (Get-Content -Raw -Path "$($dependency_dl_path)latest.json" | ConvertFrom-Json)
#$deps_import | %{ DO STH }

# Links to binaries
# TODO These you have to set manually, because the folder structure in
# extracted files will possibly change over time

$bin = @(
        [PSCustomObject]@{Name="cmake"; BinDir=""; BinPath="\bin\cmake.exe"}
        [PSCustomObject]@{Name="mingit"; BinDir=""; BinPath="\cmd\git.exe"}
        [PSCustomObject]@{Name="flex"; BinDir=""; BinPath="\win_flex.exe"}
#        [PSCustomObject]@{Name="pip"; BinDir=""; BinPath=""}
#        [PSCustomObject]@{Name="python3"; BinDir=""; BinPath=""}
        [PSCustomObject]@{Name="vcpkg"; BinDir=$vcpkg_path; BinPath="$($vcpkg_path)vcpkg.exe"}
        [PSCustomObject]@{Name="cpack"; BinDir=""; BinPath="\bin\cpack.exe"}
)




# Command to install the dependencies from pip
$pip_modules="cython numpy pillow pygments pyreadline Jinja2"

# Command to install the dependencies from vcpkg
$vcpkg_deps="dirent eigen3 fontconfig freetype harfbuzz libepoxy libogg libpng opus opusfile qt5-base qt5-declarative qt5-quickcontrols sdl2 sdl2-image"



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
# TODO Do not redownload already extracted deps
Function DownloadDependencies($arr){

     Write-Host "Downloading dependencies ..."
    
     $arr | ForEach-Object {

            # Alternative download command, not working with Github! 
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
# TODO Add generate filename for download for 32bit/64bit
Function GenerateFileNames($arr){

    Write-Host "Generating Filenames ..."

    $arr | ForEach-Object {
           $_.FileName = "$($_.DownloadLink.SubString($_.DownloadLink.LastIndexOf('/') + 1))"
          
           # Debug
           #Write-Host $_.HomeDir
           #Write-Host $_.FileName
    }
}

# Get the link for the latest version of a github repo
# Inspired by https://gist.github.com/f3l3gy/0e89dde158dde024959e36e915abf6bd
# TODO Also download a hardcoded version
# TODO $arch should be exchangable from a flag for installing just 32bit versions
Function GetLatestVersionLink{
	Param($arr, [string] $path)


    
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
           

               # ADD NEW SOFTWARE LINK GENERATION HERE
               # Move Generation of $file to new function 
               # set up for architecture-flag
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

	       #ADD NEW SOFTWARE LINK GENERATION HERE
               # >>> elseif() <<<
	       
               # TODO
               # Here should be 
               # $file = GenerateFileNames-Return value or so
               # also consider python versions not just git
               # also consider hardcoded version file

               $file="$name$version$arch$type"
    
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
               
                # TODO Archive doesn't need to be deleted while Testing
                # TODO instead of Remove-Item move to Archive-Folder
                # > and save Version string
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
Function ConnectConfigs($arr){

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


# Get direktlink to binaries
# TODO vcpkg
# python
# pip
Function GetBinaryLinks($arr){

      #$arr = $bin
      $arr | ForEach-Object {
                
               # search cache
               $is_in_path=$false;

               
               $name_temp = $_.Name
               
               # Set "cpack" as "cmake" for same directory
               if($($_.Name) -eq "cpack"){
                $name_temp = "cmake"
               }
               $lookup = ($deps | Where {$($_.Name) -eq $($name_temp)})  
               $_.BinDir = $lookup.HomeDir
               $_.BinPath = "$($lookup.HomeDir)$($_.BinPath)"
               
               # Debug for BinaryLinks
               # Write-Host $_.BinPath

               # Add Directory of executable to environent $PATH variable
               SetEnvPathFromFile -file_path $_.BinPath
                                
     }
    
}

# Set up environment $PATH variable, if not already set
Function SetEnvPathFromFile{
    PARAM($file_path)

     # Split env:Path
     $split_path = $env:Path.Split(";")
     
     # Get Dir from File
     $file_dir = "$($file_path.SubString(0,($file_path.LastIndexOf('\') + 1)))"
           
     # Test for the variable already being there
     $split_path | ?{$file_dir -eq $_} | %{ 
                    
                   # Debug
                   #Write-Host "$($file_dir) is already in env:Path!" 
                   $is_in_path = $true
              
                   }

    if(!($is_in_path)){
        # Debug
        #Write-Host "Write directory $($file_dir) to $($var)."
        Set-Item -path env:Path -value "$($env:Path);$($file_dir)"
    }

}


# Git imitating
Function GitBin([string]$address,[string]$action, [string]$path){

    # Git Binary
    $git = ($bin | Where {$($_.Name) -eq $("mingit")} | Select BinPath)

    GenerateFolders $path
    # Set-Location -Path $path

    Start-Process -FilePath $git.BinPath -ArgumentList "$($action) $($address) $($path)" -Wait

    return $path

}

# Vcpkg imitating
Function VcpkgBin([string]$cmd ="/help",[string]$software=""){

    # 64bit flag
    # TODO Testing
    if($is64bit){
        $arch="--triplet x64-windows"
    }else{
        # TODO Also remove possible environment variable
        $arch=""
    }   
   
    # vcpkg Binary
    $vcpkg = ($bin | Where {$($_.Name) -eq $("vcpkg")} | Select BinPath)

    if($($cmd) -eq "integrate install"){
       
      # integrate in OS for easier use
      $job = & Start-Process -FilePath $vcpkg.BinPath -ArgumentList "$($cmd)" -Wait

    
    }elseif($($cmd) -eq "install"){

      # install Software in $software with Architecture
      $job = & Start-Process -FilePath $vcpkg.BinPath -ArgumentList "$($cmd) $($arch) $($software)" -Wait
    }

  

}


## Main


# Create Directory for dependency downloads
GenerateDepFolders -arr $deps -path $dependency_dl_path

# Get Latest from Github
# TODO Take versions from savefile (json)
GetLatestVersionLink -arr $deps -path ""

# Generate FileNames from Link
GenerateFileNames $deps

# Download all Dependencies
# TODO changes to $deps should be done before/after, that we
# can spare out downloading process by flag
DownloadDependencies $deps

# Extract Dependencies
# TODO changes to $deps should be done before/after, that we
# can spare out extraction process by flag
ExtractDependencies -arr $deps -path $dependency_dl_path

# Link config files
# TODO This should be called in dependency of existing 
# config-files not every time
ConnectConfigs $deps

# Write Versions to file
# TODO: Export/Import function would be nice to save/restore
# configs for different versions of a toolchain
# e.g. stable, testing etc.
$deps | ConvertTo-Json -depth 100 | Out-File "$($dependency_dl_path)versions.json"


# Install Dependencies
# TODO Should test for already installed dependencies first
# otherwise jump over them
# InstallDependencies $deps

# Get Links to Binaries
GetBinaryLinks $bin

# Install Python pip modules
#$pip = & Start-Process -FilePath "pip" -ArgumentList "install $($pip_modules)" -Wait


### Till here everything works out somewhat nicely
#
# Installed: Python 3.7.3, VS build tools
# Downloaded and extracted: cmake, (min)git, flex 
# Python should be in PATH from here (from python installer)
#
# NEW: cmake, git, flex, vcpkg should be in env:Path
#
# NEW: pip modules should be installed
#
###


# Clone vcpkg
# TODO Test if vcpkg is already there
# Fetch newer commits
# Checkout latest stable
# Recompile latest stable
# Do not hardcode vcpkg path in $bin-array/hashtable
Write-Host "Please wait, while we are cloning vcpkg ..."
GitBin -address "https://github.com/Microsoft/vcpkg.git" -action "clone" -path $vcpkg_path

# Set-Location -Path "$($dependency_dl_path)vcpkg"
Write-Host "Please wait, while we are compiling vcpkg ..."

# DEBUG/TODO Do not rebuild everytime
# $bat = & "$($vcpkg_path)scripts\bootstrap.ps1"

# Integrating vcpkg in OS
# VcpkgBin -cmd "integrate install"

# Builds 64-bit packages as a standard
# Add -arch "" to make 32bit packages
# VcpkgBin -cmd "install" -software $vcpkg_deps

### Till here everything works out somewhat nicely
# Installed: Python 3.7.3, VS build tools
# Downloaded and extracted: cmake, (min)git, flex 
# Python should be in PATH from here (from python installer)
# cmake, git, flex, vcpkg should be in env:Path
#
# NEW: all the Vcpkg-Packages should be built in $arch-Version
#
###

# Clone openage
#Write-Host "Please wait, while we are cloning openage ..."
$openage_src_dir=GitBin -address "https://github.com/SFTtech/openage.git" -action "clone" -path "$($dependency_dl_path)openage"


# Saving binary paths to easily restore current status
$bin | ConvertTo-Json -depth 100 | Out-File "$($dependency_dl_path)binaries.json"


# Ready
Write-Host "Here we are ready for cmake configuring and the environment should be set up."


# Create build dir
GenerateFolders $build_dir
Set-Location $build_dir

# cmake Commands
$vcpkg_toolchain ="-DCMAKE_TOOLCHAIN_FILE=$($vcpkg_path)/scripts/buildsystems/vcpkg.cmake"
$build_flag="-G $($vs_ver) $($arch)"

# $job = & Start-Process -FilePath "cmake" -ArgumentList "$($vcpkg_toolchain) $($build_flag) $($openage_src_dir)" -Wait

# Set-Location $build_dir
# $job = & Start-Process -FilePath "cmake" -ArgumentList "--build . --config RelWithDebInfo -- /nologo /m /v:m" -Wait


# Install the DejaVu Book Font.
 # Download and extract the latest dejavu-fonts-ttf tarball/zip file.
 # Copy ttf/DejaVuSerif*.ttf font files to %WINDIR%/Fonts.
# Set the FONTCONFIG_PATH environment variable to <vcpkg directory>\installed\<relevant config>\tools\fontconfig\fonts\.
 # Copy fontconfig/57-dejavu-serif.conf to %FONTCONFIG_PATH%/conf.d.
# [Optional] Set the AGE2DIR environment variable to the AoE 2 installation directory.
# Set QML2_IMPORT_PATH to <vcpkg directory>\installed\<relevant config>\qml
# Append the following to the environment PATH:
# <openage directory>\build\libopenage\<config built> (for openage.dll)
# Path to nyan.dll (depends on the procedure chosen to get nyan)
# <vcpkg directory>\installed\<relevant config>\bin
# <QT5 directory>\bin (if prebuilt QT5 was installed)

# Open a command prompt at <openage directory>\build (or use the one from the building step):

# Add download NSIS package to $deps

# cpack -C RelWithDebInfo -V
#The installer (openage-<version>-win32.exe) will be generated in the same directory.

# Still needs to be downloaded -> $deps
# NSIS
# dejavu-fonts-ttf


# Cleanup
# CleanUp $deps


# Notes

# Menu
# 1. Auto-Toolchain (Complete)
# 2. Install from version-file (*.json)
# 3. Compile openage
# 4. Pack&Ship openage
# 5. Cleanup dev environment (Purge)
# 6. Exit

# --help, -h --> this help
# --auto-all, -a --> Go through complete toolchain and install/update as needed
# --config <File-Path.json> -> Version-File for Software
# --version, -v --> this script version
# --compile <Path to openage.git> 
# --output <Path to build-dir> or <dir> regarding your command   
# --cleanup


# Set Environment variables
# VCPKG_DEFAULT_TRIPLET=x64-windows
## Think we don't want to work with that variable, as we rather want a per command setting not a systemwide setting for vcpkg
## otherwise we need to remember it for cleanup
#
# Buildtools: C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools

# Version caching in Umgebungsvariable oder ähnlichem

# TODO Verification of Software
# pgp for windows
# sha256

# Alternative to Invoke-Webrequest
# Start-BitsTransfer -Source $_.HashFile -Destination $_.HomeDir -Asynchronous
# Start-BitsTransfer -Source $_.DownloadLink -Destination $_.HomeDir -Asynchronous -DisplayName "Downloading $_.Name ..." 