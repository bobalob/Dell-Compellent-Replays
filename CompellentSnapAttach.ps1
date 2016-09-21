Param(
    $Credential = (Get-Credential),
    [Parameter(Mandatory=$true)][string] $scSn,
    [Parameter(Mandatory=$true)][string] $serverName,
    [Parameter(Mandatory=$true)][string] $port,
    [Parameter(Mandatory=$true)][string] $TargetVolume
)

#Load the module and connect to the controller
. C:\Scripts\ConnectDellCompellent.PS1 -Credential $Credential -scSn $scSn -port $port
if ($sc -eq $null) {break}

#Check the replay doesn't already exist
$ReplayView = Get-DellScVolume -Connection $conn | ? {$_.Name -eq "Automated View of $($TargetVolume)"}
if ($ReplayView) {Write-Host "Error: Automated replay already exists for this volume, Break" -ForegroundColor Red ; Break }

#Get the most recent replay for the volume
$Replays = Get-DellScReplay -StorageCenter $sc -Connection $conn
$ReplayTarget = $Replays | ? {$_.CreateVolume -match $TargetVolume} | Sort -Property ExpireTime | Select -Last 1

Write-Host "Newest Replay for volume " -NoNewline
Write-Host "$($TargetVolume)" -NoNewline -ForegroundColor Cyan
Write-Host " : Expires " -NoNewline
Write-Host $($ReplayTarget.ExpireTime).ToString("yyyy-MM-dd hh:mm") -ForegroundColor Cyan

#Create and map a view of the replay to the target server
Write-Host "Create Replay View..."
$ReplayView = New-DellScReplayView -Instance $ReplayTarget -Name "Automated View of $($TargetVolume)" -Connection $conn -ReplayProfileList $Null
$ScServer = Get-DellScServer -Connection $conn | ? {$_.Name -match $serverName}
$VolMapping = Add-DellScVolumeToServerMap -Instance $ReplayView -Server $ScServer -Connection $conn

#Rescan Disks
Update-HostStorageCache

#Post Attach Checks
$MountedDisk = Get-Disk | ? {$_.UniqueId -eq $ReplayView.DeviceId}
if ($MountedDisk) {
  if ($MountedDisk.IsOffline) {
    Set-Disk -UniqueId $MountedDisk.UniqueId -IsOffline $false
    $MountedDisk = Get-Disk | ? {$_.UniqueId -eq $ReplayView.DeviceId}
    if ($MountedDisk.IsOffline) {
      Write-Host "Successfully connected the disk, but failed to bring online"
    } else {
      Write-Host "Successfully mounted the disk"
    }
  } else {
    Write-Host "Successfully mounted the disk"
  }
} else {
  Write-Host "Failed to mount the disk"
}