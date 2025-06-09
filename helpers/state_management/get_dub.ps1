$currentStatePath = "$PSScriptRoot/../../temp/state.json"
if (-not (Test-Path $currentStatePath)) {
	New-Item -Path $currentStatePath -Force > $null
}

$json = Get-Content $currentStatePath | ConvertFrom-Json
return $json.dub