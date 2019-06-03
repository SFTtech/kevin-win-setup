# Dependencies to be downloaded
# GitHub-Files can be referenced with their RepoName and the Flag "isGit"
# that will Download automatically the newest Release-Version
# Search for #ADD NEW SOFTWARE LINK GENERATION HERE and add a new case for the Link generation
$deps = @(
    [PSCustomObject]@{Name = "cmake"; isGit=$true; isZip=$true; isInstaller=$false; isConfig=$false; desiredVersion=""; LatestRelease =""; RepoName = "Kitware/CMake"; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""}
    [PSCustomObject]@{Name = "mingit"; isGit=$true; isZip=$true; isInstaller=$false; isConfig=$false; desiredVersion=""; LatestRelease = ""; RepoName = "git-for-windows/git"; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""}
    [PSCustomObject]@{Name = "flex"; isGit=$true; isZip=$true; isInstaller=$false; isConfig=$false; desiredVersion=""; LatestRelease =""; RepoName = "lexxmark/winflexbison"; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""}
    [PSCustomObject]@{Name = "python3"; isGit=$false; isZip=$false; isInstaller=$true; isConfig=$false; desiredVersion=""; LatestRelease = ""; RepoName = ""; DownloadLink = $python_dl; HashFile = ""; HomeDir = ""; FileName = ""}
    [PSCustomObject]@{Name = "vs_buildtools"; isGit=$false; isZip=$false; isInstaller=$true; isConfig=$false; desiredVersion=""; LatestRelease = ""; RepoName = ""; DownloadLink = "https://download.visualstudio.microsoft.com/download/pr/10413969-2070-40ea-a0ca-30f10ec01d1d/414d8e358a8c44dc56cdac752576b402/vs_buildtools.exe"; HashFile = ""; HomeDir = ""; FileName = ""; ConfigPath=""}
    [PSCustomObject]@{Name = "vs_buildtools\config"; LinkName="vs_buildtools"; isGit=$false; isZip=$false; isInstaller=$false; isConfig=$true; desiredVersion=""; LatestRelease = ""; RepoName = ""; DownloadLink = "https://raw.githubusercontent.com/simonsan/kevin-win-setup/stage2/vsconfig/build_tools.vsconfig"; HashFile = ""; HomeDir = ""; FileName = ""}
    [PSCustomObject]@{Name = "nsis"; LinkName=""; isGit=$false; isZip=$false; isInstaller=$true; isConfig=$false; desiredVersion=""; LatestRelease = ""; RepoName = ""; DownloadLink = "https://sourceforge.net/projects/nsis/files/NSIS%203/3.04/nsis-3.04-setup.exe"; HashFile = ""; HomeDir = ""; FileName = ""}
    [PSCustomObject]@{Name = "dejavu_font"; LinkName=""; isGit=$false; isZip=$true; isInstaller=$false; isConfig=$false; desiredVersion=""; LatestRelease = ""; RepoName = ""; DownloadLink = "http://sourceforge.net/projects/dejavu/files/dejavu/2.37/dejavu-fonts-ttf-2.37.zip"; HashFile = ""; HomeDir = ""; FileName = ""}

   # Preset New Download (Search for #ADD NEW SOFTWARE LINK GENERATION HERE and add a new case)
   # [PSCustomObject]@{Name = ""; isGit=""; RepoName = ""; DownloadLink = ""; HashFile = ""; HomeDir = ""; FileName = ""} 
)