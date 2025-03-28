param(
	[Parameter(Mandatory, Position = 0)]
	[string]$name
)

$globalStatePath = "$PSScriptRoot/../../temp/global.json"
if (Test-Path $globalStatePath) {
	$content = Get-Content $globalStatePath -Raw
	$json = ConvertFrom-Json $content
	try {
		$content = $json.$name
		if ([string]::IsNullOrEmpty($content)) {
			return $null
		}

		$json = ConvertFrom-Json $content
		. "$PSScriptRoot/../state_management/set_state.ps1" $content
		return $json.href
	} catch {
		return $null
	}
}