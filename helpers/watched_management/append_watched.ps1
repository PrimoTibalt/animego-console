param(
	[Parameter(Mandatory, Position = 0)]
	[string] $fullState
)

$globalStatePath = "$PSScriptRoot/../../temp/global.json"

$stateJson = ConvertFrom-Json $fullState
$name = $stateJson.name
if (Test-Path $globalStatePath) {
	$current = Get-Content $globalStatePath | ConvertFrom-Json
	if ($null -ne $current.$name) {
		$value = ConvertFrom-Json $current.$name
		# Tight coupling to state management changes
		# Room for improvement by reading properties info
		try {
			$value.episode = $stateJson.episode
		} catch {} # Movies don't have episodes
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
	New-Item -Path $globalStatePath -Force > $null
}

Set-Content $globalStatePath $newValue
