$currentStatePath = "$PSScriptRoot/../../temp/state.json"
if (-not (Test-Path $currentStatePath)) {
	New-Item -Path $curretntStatePath -Force
}

$stateContent = Get-Content $currentStatePath -Raw
. "$PSScriptRoot/append_watched.ps1" $stateContent