cls
Set-ExecutionPolicy Bypass -Scope Process -Force;

wsl --unregister Ubuntu

$ErrorActionPreference = 'Stop'

$automaticInstall = $true
$wslRootPath = "c:\WSL2"
$wslTempPath = $wslRootPath+"\temp"
$wslStagingPath = $wslTempPath+"\staging"
$wslScriptsPth = $wslRootPath+"\scripts"

Write-Host "Creating Directories"

mkdir $wslRootPath
mkdir $wslTempPath
mkdir $wslStagingPath
mkdir $wslScriptsPth

$packageArgs = @{
    packageName    = 'wsl-ubuntu-2204'
    softwareName   = 'Ubuntu 22.04 LTS for WSL'
    checksum       = 'c5028547edfe72be8f7d44ef52cee5aacaf9b1ae1ed4f7e39b94dae3cf286bc2'
    checksumType   = 'sha256'
    url            = 'https://aka.ms/wslubuntu2204'
    fileFullPath   = "$wslTempPath\ubuntu2204.appx"
    validExitCodes = @(0)
}

$wslIntalled = $false
Write-Host "Checking if WSL is installed"
if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
    $wslIntalled = $true
    Write-Host "WSL is Intalled"
}

if (!$wslIntalled) {
    Write-Error "WSL not detected! WSL is needed to install $($packageArgs.softwareName)"
    exit 1
}

$date = Get-Date
$date = $date.ToLongTimeString()
Write-Host "Downloading $($packageArgs.softwareName) at $($date)"

# Download Docker Desktop Installer
$webClient = New-Object System.Net.WebClient
$webClient.DownloadFile($($packageArgs.url), $($packageArgs.fileFullPath))

$date = Get-Date
$date = $date.ToLongTimeString()

Write-Host "$($packageArgs.softwareName) downloaded to $($packageArgs.fileFullPath) at $($date)"

Write-Host "Downloading Scripts"
Invoke-WebRequest -Uri $("https://raw.githubusercontent.com/Evilazaro/MicrosoftDevBox/Dev/Deploy/ARMTemplates/computeGallery/createUser.sh") -OutFile $($wslScriptsPth+"\createUser.sh")
Invoke-WebRequest -Uri $("https://raw.githubusercontent.com/Evilazaro/MicrosoftDevBox/Dev/Deploy/ARMTemplates/computeGallery/installUtils.sh") -OutFile $($wslScriptsPth+"\installUtils.sh")
Write-Host "Scripts downloaded to $($wslScriptsPth)"

if ($automaticInstall) {
    $wslName = 'Ubuntu'
    $wslInstallationPath = "c:\WSL2\$wslName"
    $wslUsername = "ubuntu-usr"

    # create staging directory if it does not exists
    if (-Not (Test-Path -Path $wslTempPath\staging)) { $dir = mkdir $wslTempPath\staging }

    Move-Item $wslTempPath\ubuntu2204.appx $wslTempPath\staging\$wslName-Temp.zip -Force

    Expand-Archive $wslTempPath\staging\$wslName-Temp.zip $wslTempPath\staging\$wslName-Temp -Force

    Move-Item $wslTempPath\staging\$wslName-Temp\Ubuntu_2204.1.7.0_x64.appx $wslTempPath\staging\$wslName.zip -Force

    Expand-Archive $wslTempPath\staging\$wslName.zip $wslTempPath\staging\$wslName -Force

    if (-Not (Test-Path -Path $wslInstallationPath)) {
        mkdir $wslInstallationPath
    }

    $date = Get-Date
    $date = $date.ToLongTimeString()
    Write-Host "Importing/Installing WSL at $($date)"
    wsl --import $wslName $wslInstallationPath $wslTempPath\staging\$wslName\install.tar.gz
    Write-Host "Ubuntu Imported succesfuly at $($date)"

    Write-Host "Moving Ubuntu to staging directory at $($date)"
    Move-Item $wslTempPath\staging\$wslName-Temp.zip $wslTempPath\ubuntu2204.appx -Force 
    Write-Host "Ubuntu Moved to statgin directory succesfully at $($date)"

    # Write-Host "Deleting Ubuntu from staging directory at $($date)"
    # Remove-Item -r $wslTempPath\staging\ -Force
    # Write-Host "Ubuntu deleted succesfully from staging directory at $($date)"

    $date = Get-Date
    $date = $date.ToLongTimeString()
    Write-Host "Ubuntu 22.04 LTS for WSL Installed at $($date)"

    $date = Get-Date
    $date = $date.ToLongTimeString()
    
    Write-Host "Creating Ubuntu User at $($date)"
    wsl -d $wslName -u root bash -ic "/mnt/c/WSL2/scripts/createUser.sh $wslUsername ubuntu"
    
    $date = Get-Date
    $date = $date.ToLongTimeString()
    Write-Host "Ubuntu User Created at $($date)"

    $date = Get-Date
    $date = $date.ToLongTimeString()
    Write-Host "Updating Ubuntu Use at $($date)"
    
    wsl -d $wslName -u root bash -ic "/mnt/c/temp/configureUbuntuFrontEnd.sh" 
    wsl -d $wslName -u root bash -ic "DEBIAN_FRONTEND=noninteractive /mnt/c/temp/updateUbuntu.sh"

    $date = Get-Date
    $date = $date.ToLongTimeString()
    Write-Host "Ubuntu Updated at $($date)"
    
    Write-Host "Restarting WSL Distro"
    wsl -t $wslName
}
else {
    Add-AppxPackage $packageArgs.fileFullPath
}