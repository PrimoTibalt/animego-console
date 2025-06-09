param(
	[Parameter(Mandatory, Position = 0)]
	[string]$name,
	[Parameter(Mandatory, Position = 1)]
	[string]$value
)

$currentStatePath = "$PSScriptRoot/../../temp/state.json"
if (-not (Test-Path $currentStatePath)) {
	New-Item -Path $currentStatePath -Force > $null
}

$json = Get-Content $currentStatePath | ConvertFrom-Json
try {
	$json.$name = $value
} catch {
	$json | Add-Member -Name $name -MemberType NoteProperty -Value $value
}

ConvertTo-Json $json | Set-Content $currentStatePath