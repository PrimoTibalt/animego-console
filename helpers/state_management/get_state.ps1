$currentStatePath = "$PSScriptRoot/../../temp/state.json"
if (-not (Test-Path $currentStatePath)) {
	New-Item -Path $currentStatePath -Force > $null
}

$stateJson = Get-Content $currentStatePath | ConvertFrom-Json
return $stateJson
