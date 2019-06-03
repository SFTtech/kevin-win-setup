# Copyright 2019 the openage authors. See LICENSE for legal info.
# Licensed under GNU General Public License v3.0


# Flag for DRY RUN -> TODO
# $DRY_RUN=false;

# IMPORTANT NOTE!
# Need to set the following command manually, to run this script on a standard Win10 machine
# don't close the Powershell afterwards because for security reasons scripts are just allowed
# for the current powershell process
# >>> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# PLEASE SEARCH FOR "CHANGEME" IN THIS SCRIPT AND ADJUST THE VALUES TO YOUR LIKING! 

# CHANGEME: IMPORTANT STANDARD PATHS 

## Path to the file with all the dependencies and versions
## You could also set the $OPENAGE_VF environment variable to the version file you like
#$version_file=$env:OPENAGE_VF
$version_file="C:\Users\Jameson\Documents\git-projects\kevin-win-setup\dep-configs\stable.json"

## Change to preferred download path
$dependency_dl_path="$env:HOMEDRIVE\openage-dl\";

## Change Build-Directory
$build_dir="$env:HOMEDRIVE\openage-build\";

## vcpkg should be saved in
$vcpkg_path="$($dependency_dl_path)vcpkg\"

# Command to install the dependencies from pip
$pip_modules="cython numpy pillow pygments pyreadline Jinja2"

# Command to install the dependencies from vcpkg
$vcpkg_deps="dirent eigen3 fontconfig freetype harfbuzz libepoxy libogg libpng opus opusfile qt5-base qt5-declarative qt5-quickcontrols sdl2 sdl2-image"


 # ARCHITECTURE 32/64 bit

## (DEBUG) Set architecture manually
# $is64bit=$true

# CHANGEME: Set the environment variable on your system $env:OPENAGEx64 
# to either TRUE (for 64bit builds) or FALSE (for 32bit builds)


# Deal with vcpkg standard triplet for 64bit compilation
if($($env:VCPKG_DEFAULT_TRIPLET) -eq "x64-windows"){
    
    # Set 64bit for us
    $is64bit=$true
    
    # Unset this variable as we have one only for openage-x64
    Remove-Item -Path env:VCPKG_DEFAULT_TRIPLET
}


## Set architecture with environment variables
## Standard ist 64-bit
if(!($env:OPENAGEx64) -or !($is64bit)){
    $is64bit=$false
    $env:OPENAGEx64=$false
    Write-Host "32bit Flag activated! Everything will be downloaded and build in 32bit/x86 architecture!"
    
    #python-dl-arch
    $python_dl_arch=""

    #git-dl-arch
    $git_dl_arch="-32-bit"

    #cmake-dl-arch
    $cmake_dl_arch="-win32-x86"  
    
    #cmake
    $cmake_arch = "Win32"

    #vcpkg
    $vcpkg_arch=""

}elseif($is64bit -or $env:OPENAGEx64){
    $is64bit=$true
    $env:OPENAGEx64=$true
    Write-Host "64bit Flag activated! Everything will be downloaded and build in 64bit/x64 architecture!"

    #python-dl-arch
    $python_dl_arch="-amd64"

    #git-dl-arch
    $git_dl_arch="-64-bit"

    #cmake-dl-arch
    $cmake_dl_arch="-win64-x64"

    #cmake
    $cmake_arch = "Win64"

    #vcpkg
    $vcpkg_arch="--triplet x64-windows"

}

# cmake Visual Studio version
$build_vs_ver = "Visual Studio 15 2017"

# Links to binaries
# CHANGEME: The BinPath is depending on the structure of the archive itself
# These you have to set manually, because the folder structure in
# extracted files will possibly change over time

$bin = @(
        [PSCustomObject]@{Name="cmake"; BinDir=""; BinPath="\bin\cmake.exe"}
        [PSCustomObject]@{Name="mingit"; BinDir=""; BinPath="\cmd\git.exe"}
        [PSCustomObject]@{Name="flex"; BinDir=""; BinPath="\win_flex.exe"}
        [PSCustomObject]@{Name="vcpkg"; BinDir=$vcpkg_path; BinPath="$($vcpkg_path)vcpkg.exe"}
        [PSCustomObject]@{Name="cpack"; BinDir=""; BinPath="\bin\cpack.exe"}
        [PSCustomObject]@{Name="nsis"; BinDir=""; BinPath="\NSIS.exe"}
#       [PSCustomObject]@{Name="pip"; BinDir=""; BinPath=""}
#       [PSCustomObject]@{Name="python3"; BinDir=""; BinPath=""}
)

# TODO $deps nochmal initialisieren für $_.installDir




# VERSION CONFIGURATION OF DEPENDENCIES

# Write version file
Function WriteVersionsToFile($arr, [string]$dir, [string]$name="versions.json"){
    
    # GenerateFolders
    $dir_created = GenerateFolders $dir

    # Write FileOut
    #$arr | ConvertTo-Json -depth 100 | Out-File "$($dir_created)$name"

}

# Import versions from file
# TODO Testing
Function GetVersionsFromFile{
    Param([string]$versionfile_path)
    
    if($versionfile_path){
        Write-Host "Version file will be imported from $versionfile_path"
        return (Get-Content -Raw -Path $versionfile_path | ConvertFrom-Json)
    }
    
    #$deps_import | %{ DO STH }
 
}

# Function to create folderstructure
Function GenerateFolders($path){
    $global:foldPath=$null
    
    foreach($foldername in $path.split("\")){
          $global:foldPath+=($foldername+"\")

          if(!(Test-Path $global:foldPath)){
              New-Item -ItemType Directory -Path $global:foldPath
              Write-Host "$global:foldPath Folder created successfully!"
          }elseif((Test-Path $global:foldPath)){
              # Write-Host "$global:foldPath Folder already exists!"
          }

          
         # elseif($DRY_RUN){
         #        Write-Host "DRYRUN: $global:foldPath folder was not created!"
         #}

    }
   
   # Not sure if we really need that, commented out 
   #return $global:foldPath    
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
           
                Write-Host "Downloading $($_.Name) $($_.LatestRelease) ..."

                # Debug
                Write-Host $_.DownloadLink
                Write-Host $output


                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            
                if(($_.Name) -eq "vs_buildtools"){

                        # Visual Studio 17 CE (advanced options) - Build tools
                        $job = Invoke-WebRequest -Uri $source  -OutFile $output -Headers @{"method"="GET"; "authority"="download.visualstudio.microsoft.com"; "scheme"="https"; "path"="/download/pr/10413969-2070-40ea-a0ca-30f10ec01d1d/414d8e358a8c44dc56cdac752576b402/vs_buildtools.exe"; "upgrade-insecure-requests"="1"; "dnt"="1"; "user-agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36"; "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3"; "referer"="https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=BuildTools&rel=15"; "accept-encoding"="gzip, deflate, br"; "accept-language"="en-US,en;q=0.9"}
                 

                }elseif(($_.Name) -eq "nsis"){
                    
                        # NSIS
                        $job = Invoke-WebRequest -Uri $source -OutFile $output -Headers @{"Upgrade-Insecure-Requests"="1"; "DNT"="1"; "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36"; "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3"; "Referer"="https://sourceforge.net/projects/nsis/files/NSIS%203/3.04/nsis-3.04-setup.exe/download?use_mirror=netix&download="; "Accept-Encoding"="gzip, deflate, br"; "Accept-Language"="en-US,en;q=0.9"; "Cookie"="eupubconsent=BOhQ8W7OhQ8W7AKASAENAAAA-AAAAA; euconsent=BOhQ8W7OhQ8W7AKASBENCU-AAAAnd7_______9______9uz_Ov_v_f__33e87_9v_l_7_-___u_-3zd4u_1vf99yfm1-7etr3tp_87ues2_Xur__59__3z3_9phPrsk89r6337A; googlepersonalization=OhQ8W7OhQ8W7gA; _cmpRepromptOptions=OhQ8W7OhQ8W7IA"}
                

                }elseif(($_.Name) -eq "dejavu_font"){

                        # Dejavu-Font
                        Invoke-WebRequest -Uri $source -OutFile $output -Headers @{"Upgrade-Insecure-Requests"="1"; "DNT"="1"; "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36"; "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3"; "Referer"="https://sourceforge.net/projects/dejavu/files/dejavu/2.37/dejavu-fonts-ttf-2.37.zip/download"; "Accept-Encoding"="gzip, deflate, br"; "Accept-Language"="en-US,en;q=0.9"; "Cookie"="eupubconsent=BOhQ8W7OhQ8W7AKASAENAAAA-AAAAA; euconsent=BOhQ8W7OhQ8W7AKASBENCU-AAAAnd7_______9______9uz_Ov_v_f__33e87_9v_l_7_-___u_-3zd4u_1vf99yfm1-7etr3tp_87ues2_Xur__59__3z3_9phPrsk89r6337A; googlepersonalization=OhQ8W7OhQ8W7gA; _cmpRepromptOptions=OhQ8W7OhQ8W7IA"}
                       
                }else{
                        # Other dependencies without referrer
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
# TODO $arch should be exchangable from a flag for installing just 32bit versions
Function GenerateFileNames($arr){

    Write-Host "Generating Filenames ..."

    $arr | ForEach-Object {
           $_.FileName = "$($_.DownloadLink.SubString($_.DownloadLink.LastIndexOf('/') + 1))"
          
           # Debug
           #Write-Host $_.HomeDir
           #Write-Host $_.FileName
    }
}


# Get the link for the (latest) version of a github repo
# Inspired by https://gist.github.com/f3l3gy/0e89dde158dde024959e36e915abf6bd
Function GetVersionLink{
	Param($arr, [string] $path)
 

    $arr | ForEach-Object {

           # Github
           if(($_.isGit) -eq $true){

               if(!($_.desiredVersion)){

               Write-Host "Get the latest version of Github-Releases ..."

               $releases = "https://api.github.com/repos/$($_.RepoName)/releases"
           
               Write-Host "Determining latest release for $($_.Name)"
               [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                
               $versionRequest = ((ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri  $releases -UseBasicParsing)) | Where {$_.prerelease -eq $false})[0]

               $_.desiredVersion = $false
               $_.LatestRelease = $versionRequest[0].tag_name

                    Write-Host "The latest release of $($_.Name) is $($_.LatestRelease)."

               }else{

                    Write-Host "Using hardcoded version $($_.desiredVersion) of $($_.Name)..."
                    $_.LatestRelease = $_.desiredVersion
               }

               #$_.DownloadLink = ($versionRequest | Where {$_.content_type -eq "application/zip"})
           

               # ADD NEW SOFTWARE LINK GENERATION HERE
               # set up for architecture-flag
               # >>>
          
               if(($_.Name) -eq "mingit"){
                   #MinGit-2.21.0-64-bit.zip
                   #MinGit-2.21.0-32-bit.zip
                   $name = "$($_.Name)-"
                   $version=($_.LatestRelease.Substring(1))
                   $version= $version.Substring(0,$version.Length-10)
                   $arch=$git_dl_arch
                   $type=".zip"

               }elseif(($_.Name) -eq "cmake"){
                   #cmake-3.14.5-win64-x64.zip 
                   #cmake-3.14.5-win32-x86.zip
                   $name = "$($_.Name)-"  
                   $version=$_.LatestRelease.Split("v")[1]
                   $arch=$cmake_dl_arch
                   $type=".zip"
           
               }elseif(($_.Name) -eq "flex"){
                   #win_flex_bison-2.5.18.zip 
                   $name = "win_$($_.Name)_bison-"  
                   $version=$_.LatestRelease.Split("v")[1]
                   $arch=""
                   $type=".zip"
           
               
               }

	       #ADD NEW SOFTWARE LINK GENERATION FOR GITHUB HERE
               # >>> elseif() <<<

               $file="$name$version$arch$type"
    
               # Debug
               # Write-Host "DownloadLink for $($_.RepoName) is"
               
               $_.DownloadLink="https://github.com/$($_.RepoName)/releases/download/$($_.LatestRelease)/$($file)"
               
               # Debug
               # Write-Host $_.DownloadLink

 

          }elseif(($_.isGit) -eq $false){

                $_.LatestRelease = $_.desiredVersion

                if(($_.Name) -eq "python3"){

                       $arch=$python_dl_arch
                       $_.DownloadLink="https://www.python.org/ftp/python/$($_.desiredVersion)/python-$($_.desiredVersion)$($arch).exe"


                }elseif(($_.Name) -eq "nsis"){

                         # Sourceforge
                         $_.DownloadLink="https://kent.dl.sourceforge.net/project/nsis/NSIS%203/$($_.desiredVersion)/nsis-$($_.desiredVersion)-setup.exe"
                         
            
                }elseif(($_.Name) -eq "dejavu_font"){

                         # Sourceforge
                         $_.DownloadLink="https://kent.dl.sourceforge.net/project/dejavu/dejavu/$($_.desiredVersion)/dejavu-fonts-ttf-$($_.desiredVersion).zip"

                }     


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
                # TODO Not Working
                write-host "$($_.Name) installed succesfully."
             }

              # TODO Add install-dir to object
              # $_.InstallDir = "$($_.HomeDir)"

           }elseif(($_.Name) -eq "vs_buildtools"){

             # Installer Routine for VS Buildtools
             Write-Host "Installing $($_.Name), this can take a longer time. Do not close this window!"
             $setup = Start-Process "$($_.HomeDir)$($_.FileName)" -ArgumentList "-p --addProductLang En-us --norestart --noUpdateInstaller --downloadThenInstall --force --config $($_.ConfigPath)" -Wait

             if ($setup.exitcode -eq 0){
                # TODO Not Working
                write-host "$($_.Name) installed succesfully."
             }

              # TODO Add install-dir to object
              # $_.InstallDir = "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools"

           }elseif(($_.Name) -eq "nsis"){

             # TODO Installer Routine for NSIS
             Write-Host "Installing $($_.Name), this can take a longer time. Do not close this window!"
             $setup = Start-Process "$($_.HomeDir)$($_.FileName)" -ArgumentList "/S /D=$($_.HomeDir)$($_.Name)-$($_.LatestRelease)\" -Wait
             
             if ($setup.exitcode -eq 0){
                # TODO Not Working
                write-host "$($_.Name) installed succesfully."
             }
            
             # TODO Add install-dir to object
             # Set InstallDir to directory of install for later use for $bin and $PATH
             # $_.InstallDir = "$($_.HomeDir)$($_.Name)-$($_.LatestRelease)"
         
           }elseif(($_.Name) -eq "dejavu_font"){

             # TODO Installer Routine for dejavu_font
             Write-Host "Installing $($_.Name), this can take a longer time. Do not close this window!"
             #$setup = Start-Process "$($_.HomeDir)$($_.FileName)" -ArgumentList "/S /D=$($_.HomeDir)$($_.Name)-$($_.LatestRelease)\" -Wait
             
             if ($setup.exitcode -eq 0){
                # TODO Not Working
                write-host "$($_.Name) installed succesfully."
             }

           }

         }

    }

}


# Get direktlink to binaries
Function GetBinaryLinks($arr){

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

   
    # vcpkg Binary
    $vcpkg = ($bin | Where {$($_.Name) -eq $("vcpkg")} | Select BinPath)

    if($($cmd) -eq "integrate install"){
       
      # integrate in OS for easier use
      $job = & Start-Process -FilePath $vcpkg.BinPath -ArgumentList "$($cmd)" -Wait

    
    }elseif($($cmd) -eq "install"){

      # install Software in $software with Architecture
      $job = & Start-Process -FilePath $vcpkg.BinPath -ArgumentList "$($cmd) $($vcpkg_arch) $($software)" -Wait
    }

}


## Main

# Import from version file
$deps = GetVersionsFromFile $version_file

# Create Directory for dependency downloads
GenerateDepFolders -arr $deps -path $dependency_dl_path

# Get Latest from Github
# TODO Take versions from savefile (json)
GetVersionLink -arr $deps -path ""

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
#$deps | ConvertTo-Json -depth 100 | Out-File "$($dependency_dl_path)recent.json"


# Install Dependencies
# TODO Should test for already installed dependencies first
# otherwise jump over them or even remove possible conflict files
InstallDependencies $deps

# Get Links to Binaries
GetBinaryLinks $bin

$deps | ConvertTo-Json -depth 100 | Out-File "$($dependency_dl_path)recent.json"

# Install Python pip modules
$pip = & Start-Process -FilePath "pip" -ArgumentList "install $($pip_modules)" -Wait


### Till here everything works out somewhat nicely
#
# Installed: Python 3.7.3, VS build tools, NSIS
# Downloaded and extracted: cmake, (min)git, flex 
# Python should be in PATH from here (from python installer)
#
# NEW: cmake, git, flex, vcpkg should be in env:Path
#
# NEW: pip modules should be installed
#
###


# Clone vcpkg
Write-Host "Please wait, while we are cloning vcpkg ..."
GitBin -address "https://github.com/Microsoft/vcpkg.git" -action "clone" -path $vcpkg_path

# Set-Location -Path "$($dependency_dl_path)vcpkg"
Write-Host "Please wait, while we are compiling vcpkg ..."

# DEBUG/TODO Do not rebuild everytime
# Check with hash-file against hash of vcpkg.exe
# and if vcpkg.exe is already there unchanged
$bat = & "$($vcpkg_path)scripts\bootstrap.ps1"

# Get Hash of vcpkg.exe for $bin_hashes
# Get-FileHash -Path <Path> -Algorithm SHA512

# Integrating vcpkg in OS
VcpkgBin -cmd "integrate install"

# Builds defined packages for the defined architecture 
VcpkgBin -cmd "install" -software $vcpkg_deps

### Till here everything works out somewhat nicely
# Installed: Python 3.7.3, VS build tools, NSIS
# Downloaded and extracted: cmake, (min)git, flex 
# Python should be in PATH from here (from python installer)
# cmake, git, flex, vcpkg should be in env:Path
#
# NEW: all the Vcpkg-Packages should be built in $arch-Version
#
###

# Clone openage
Write-Host "Please wait, while we are cloning openage ..."
$openage_src_dir=GitBin -address "https://github.com/SFTtech/openage.git" -action "clone" -path "$($dependency_dl_path)openage"


# Saving binary paths to easily restore current status
#$bin | ConvertTo-Json -depth 100 | Out-File "$($dependency_dl_path)binaries.json"

# Ready
Write-Host "Here we are ready for cmake configuring and the environment should be set up."


####
#
#
# Building of openage could start from now on
# TODO Check to clean the Build-Dir before making new build
#
####

# Create build dir depending on building architecture
$build_dir_arch="$($build_dir)$($cmake_arch)"
GenerateFolders $build_dir_arch
Set-Location $build_dir_arch

# cmake Commands
#$vcpkg_toolchain ="-DCMAKE_TOOLCHAIN_FILE=$($vcpkg_path)/scripts/buildsystems/vcpkg.cmake"
#$build_flag="-G $($vs_ver) $($cmake_arch)"


#$job = & Start-Process -FilePath "cmake" -ArgumentList "$($vcpkg_toolchain) $($build_flag) $($openage_src_dir)" -Wait

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


# Stage3.ps1 could be called from here on I guess
# we could also pass the binary paths if we need to
# then we should use the Start-Process -FilePath powershell -ArgumentList $stage3_path -Wait
# syntax instead of the batch-syntax hier
# $stage3 = & "stage3.ps1"



# Cleanup
# CleanUp $deps
# Cleanup environment variables for bin-paths


# Notes

# Import BITS for file transfers
# Import-Module BitsTransfer

# OTHER CMAKE DEPENDENCIES
# BZRCOMMAND-NOTFOUND
# CMAKE_MT-NOTFOUND
# COVERAGE_COMMAND-NOTFOUND
# CVSCOMMAND-NOTFOUND 
# DOXYGEN_DOT_EXECUTABLE-NOTFOUND
# DOXYGEN_EXECUTABLE-NOTFOUND
# GITCOMMAND-NOTFOUND
# HGCOMMAND-NOTFOUND
# MEMORYCHECK_COMMAND-NOTFOUND
# P4COMMAND-NOTFOUND
# PKG_CONFIG_EXECUTABLE-NOTFOUND
# SLURM_SBATCH_COMMAND-NOTFOUND
# SLURM_SRUN_COMMAND-NOTFOUND
# SVNCOMMAND-NOTFOUND
# _VCPKG_CL-NOTFOUND
# OGG_LIB-NOTFOUND


# TODO Test if vcpkg is already there
# Fetch newer commits
# Checkout latest stable
# Recompile latest stable
# Do not hardcode vcpkg path in $bin-array/hashtable



# TODO
# Save progress inside the script to return after being interrupted
# Implement errors/exception checks
# Make os-snapshots in between to secure state?

# Set Environment variables
# 
## Think we don't want to work with that variable, as we rather want a per command setting not a systemwide setting for vcpkg
## otherwise we need to remember it for cleanup
#
# Buildtools: C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools

# ERROR array
# take one array to collect all the errors/warnings over the script
# important ones should stop the script and throw an big warning in a window

# TODO Verification of Software
# Hash-Function for SHA512
# Get-FileHash -Path $gethash -Algorithm SHA512

# Getting Hashes for subfolders of x-layers
# Get-FileHash -Path C:\openage-dl\*\*\*\*   -Algorithm SHA512
# Possible things to Hash:
# vcpkg build -> vcpkg.exe to check whether already build completely (if build broke before)
# Function to make hash of every bin and save it in $hash --> json
# Function should check for integrity of binaries


# Alternative to Invoke-Webrequest
# Start-BitsTransfer -Source $_.HashFile -Destination $_.HomeDir -Asynchronous
# Start-BitsTransfer -Source $_.DownloadLink -Destination $_.HomeDir -Asynchronous -DisplayName "Downloading $_.Name ..." 


# IDEA Move out everything which could be an extra configuration of openage building
# e.g. 32bit MSVC 2019 or 64bit MSVC 2017
# a bit like a "Desired State Configuration" for dependencies
# DSC-stable.json should have one big configuration of
# Array/Hash-Table->$dep
# Folder-Configs
# Architecture
# Compiler version
# standard/binary paths with BinDir = $dep_dl_path + $binary_name

# IDEA Menu
# 1. Auto-Toolchain (Complete)
# 2. Install from version-file (*.json)
# 3. Compile openage
# 4. Pack&Ship openage
# 5. Cleanup dev environment (Purge)
# 6. Exit

# IDEA CLI
# --help, -h --> this help
# --auto-all, -a --> Go through complete toolchain and install/update as needed
# --config <File-Path.json> -> Version-File for Software
# --version, -v --> this script version
# --compile <Path to openage.git> 
# --output <Path to build-dir> or <dir> regarding your command   
# --cleanup