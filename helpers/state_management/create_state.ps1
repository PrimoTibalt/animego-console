param(
	[Parameter(Mandatory, Position = 0)]
	[string]$animeName,
	[Parameter(Mandatory, Position = 1)]
	[string]$animeHref
)

$currentStatePath = "$PSScriptRoot/../../temp/state.json"
if (Test-Path $currentStatePath) {
	$currentState = Get-Content $currentStatePath
	if (-not [string]::IsNullOrEmpty($currentState)) {
		$currentJson = ConvertTo-Json $currentState
		if ($currentJson.name -eq $animeName) {
			return
		}
	}
} else {
	New-Item -Path $currentStatePath -Force > $null
}

$json = "{""name"": ""$animeName"", ""href"": ""$animeHref""}"
Set-Content $currentStatePath $json