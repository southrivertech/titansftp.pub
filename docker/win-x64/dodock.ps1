param($hostName='myhost',$arch='windows',$repo="southrivertech",$image="titanftp", $tagName="latest")

# 
# Sample script file
#


#
# double check. if it's still bad, use default
#
if (($hostName -eq $null) -or ($hostName -eq "")) {
    Write-Host "Invalid hostname, bye"
    exit
}

#
# grab the architecture platform, windows or linux.
#
$plats = @('windows','linux') 
if ($plats -notcontains $arch) {
    $arch = read-host -Prompt "platform?: ($plats) "
}
if ($plats -notcontains $arch) {
    Write-Host "Invalid platform, bye"
    exit
}

#
# Ensure Docker is configured for the proper engine
#
$dockerCliPath = "C:/Program Files/Docker/Docker/DockerCli.exe"
$proc = $null

Write-Host "Setting Docker engine for [$arch] containers..."
if ( $arch -ne "windows" ) {
    $proc = Start-Process -FilePath $dockerCliPath -ArgumentList -SwitchLinuxEngine -Wait -NoNewWindow 
}
else {
    $proc = Start-Process -FilePath $dockerCliPath -ArgumentList -SwitchWindowsEngine -Wait -NoNewWindow 
}
if ($proc) { 
    $proc.WaitForExit() 
}


#
# Create the volumes
#

#
# Create volumes
# Create a Logs, Data, and Config tied to the host
#
$cfgVol = "srxcfg-" + $hostName
$logsVol = "srxlog-" + $hostName 
$dataVol = "srxdata-" + $hostName
$vols = @($cfgVol,$logsVol,$dataVol)

Write-Host "Creating Volumes..."
Write-Host " SysConfig Volume: [$cfgVol]"
Write-Host " Logs Volume: [$logsVol]"
Write-Host " Data Volume: [$dataVol]"

foreach ($v in $vols) {
    Write-Host " Creating [$v]..."
    docker volume create $v 
    docker volume inspect $v
}

#
# These ports will be open on the container
#
$sshPort = 22       # SFTP/SSH
$ftpsPort = 990     # Implicit FTP/S
$httpsPort = 443    # WebUI
$lasPort = 31443    # Local Administration Console (LAS)
$rasPort = 41443    # Remote Administration Console (RAS)
$ipAddr = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -ne "Disconnected" } ).IPv4Address.IPAddress


#
# Start the docker instance
#
$repo = "southrivertech"
$imageName = "$repo`/$image`:$tagName"

#
# default folders
#
$defCfgDir = "C:\ProgramData\South River Technologies\srxserver"
$defLogDir = "C:\Srtlogs"
$defDataDir = "c:\srtdata"


Write-Host "Starting container instance"
Write-Host " Image: [$imageName]"
Write-Host " Name: [$hostName]"

# pull
docker pull $imageName
#docker run -d --name $hostName -p $ipAddr`:$sshPort`:$sshPort -p $ipAddr`:$ftpsPort`:$ftpsPort -p $ipAddr`:$httpsPort`:$httpsPort -p $ipAddr`:$lasPort`:$lasPort -v $cfgVol`:$defCfgDir -v $logsVol`:$defLogDir -v $dataVol`:$defDataDir $imageName 
docker run -d --name $hostName -p $sshPort`:$sshPort -p $ftpsPort`:$ftpsPort -p $httpsPort`:$httpsPort -p $lasPort`:$lasPort -p $rasPort`:$rasPort -v $cfgVol`:$defCfgDir -v $logsVol`:$defLogDir -v $dataVol`:$defDataDir $imageName 

$ipAddr = docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $hostName

#
# launch browser
#
Start-Process "https://$ipAddr`:$lasPort" 
Start-Process "https://$ipAddr`:$rasPort"
Start-Process "sftp://$ipAddr`:$sshPort"
Start-Process "ftps://$ipAddr`:$ftpsPort"
Start-Process "ftps://$ipAddr`:$httpsPort"


Write-Host "Complete!"







