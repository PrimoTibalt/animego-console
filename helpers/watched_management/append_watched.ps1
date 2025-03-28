param(
	[Parameter(Mandatory, Position = 0)]
	[string] $fullState
)

$path = "$PSScriptRoot/../../temp/global.json"

$stateJson = ConvertFrom-Json $fullState
$name = $stateJson.name
if (Test-Path $path) {
	$current = Get-Content $path | ConvertFrom-Json
	if ($null -ne $current.$name) {
		$value = ConvertFrom-Json $current.$name
		# Tight coupling to state management changes
		# Room for improvement by reading properties info
		$value.episode = $stateJson.episode
		$value.dub = $stateJson.dub
		$value.href = $stateJson.href
		$current.$name = ConvertTo-Json $value
	} else {
		$current | Add-Member -MemberType NoteProperty -Name $stateJson.name -Value $fullState
	}

	$newValue = ConvertTo-Json $current
} else {
	$current = ConvertFrom-Json "{""$name"":""""}"
	$current.$name = $fullState

	$newValue = ConvertTo-Json $current
}

Set-Content $path $newValue
