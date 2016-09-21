Param (
    [Parameter(Mandatory=$true)]$Credential = (Get-Credential),
    [Parameter(Mandatory=$true)][string] $scSn,
    [Parameter(Mandatory=$true)][string] $port,
    $DellPSLocation="C:\Scripts\DellStoragePowerShellSDK_v2_2_1_362\"
)

if (!(Test-Path $DellPSLocation)) {
  Write-Host "Dell PS Location Path does not exist"
  Break
}

#Import Dell Powershell Cmdlets
Import-Module "$($DellPSLocation)\DellStorage.ApiCommandSet.psd1"

# Get the Connection to the Data Collector
$conn = Connect-DellApiConnection -Host $hostname -Port $port -User $Credential.UserName -password $Credential.Password
if($conn -eq $null) {
    Write-Host "Error Connecting to the Data Collector" -ForegroundColor Red
    break
}

$sc = Get-DellStorageCenter -Connection $conn -SerialNumber $scSn
if($sc -eq $null) {
	Write-Host "Error Connecting to the Storage Center" -ForegroundColor Red
	break
}

Write-Host "Connected to Storage Center: " -NoNewLine
Write-Host $sc -ForegroundColor Cyan
