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

#Get local disk object and SAN replay view
$ReplayView = Get-DellScVolume -Connection $conn | ? {$_.Name -eq "Automated View of $($TargetVolume)"}
$LocalDisk = Get-Disk | ? {$_.UniqueId -eq $ReplayView.DeviceId}

#Offline local disk
Write-Host "Off-lining and detching disk $($LocalDisk.Number)"
$LocalDisk
Set-Disk -UniqueId $LocalDisk.UniqueId -IsOffline $True
$LocalDisk = Get-Disk | ? {$_.UniqueId -eq $ReplayView.DeviceId}

#Post Detach Checks
if ($LocalDisk.IsOffline) {
  #Delete SAN replay view
  $Removed = Remove-DellScVolume -Instance $ReplayView -Connection $conn -Confirm:$False
  #Rescan Disks
  Update-HostStorageCache

  if (Get-Disk | ? {$_.UniqueId -eq $ReplayView.DeviceId}) {
    Write-Host "Failed to remove the disk from this server"
  } else {
    $ReplayView = Get-DellScVolume -Connection $conn | ? {$_.Name -eq "Automated View of $($TargetVolume)"}
    if ($ReplayView) {
      Write-Host "Failed to remove the LUN from Dell SC"
    } else {
      Write-Host "Successfully Removed the Disk"
    }
  }
} else {
  Write-Host "Failed to offline the disk"
}
