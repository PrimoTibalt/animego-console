Write-Host 'This script registers animego-cli as Enter-Anime function in your terminal'
Write-Host 'You need to reopen your terminal for change to take effect'
$functionName = 'Enter-Anime'
$profileDirectory = Split-Path $PROFILE
if (-not (Test-Path $profileDirectory)) {
	New-Item -Path $profileDirectory -ItemType Directory -Force > $null
}

if (-not (Test-Path $PROFILE)) {
	New-Item -Path $PROFILE -ItemType File -Force > $null
}

if (-not (Select-String -Path $PROFILE -Pattern $functionName -SimpleMatch -Quiet)) {
	"
	function $functionName {
	    & `"$PSScriptRoot/run.ps1`"
	}
	" >> $PROFILE
}
