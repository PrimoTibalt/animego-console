param(
	[Parameter(Mandatory, Position = 0)]
	[string]$animeName
)

if (Test-Path "$PSScriptRoot/../../temp/state.json") {
	$currentState = Get-Content "$PSScriptRoot/../../temp/state.json" 
	if (-not [string]::IsNullOrEmpty($currentState)) {
		$currentJson = ConvertTo-Json $currentState
		if ($currentJson.name -eq $animeName) {
			return
		}
	}
}

$json = "{""name"": ""$animeName""}"
Set-Content "$PSScriptRoot/../../temp/state.json" $json