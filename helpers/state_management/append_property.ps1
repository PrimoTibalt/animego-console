param(
	[Parameter(Mandatory, Position = 0)]
	[string]$name,
	[Parameter(Mandatory, Position = 1)]
	[string]$value
)

$json = Get-Content "$PSScriptRoot/../../temp/state.json" | ConvertFrom-Json
try {
	$json.$name = $value
} catch {
	$json | Add-Member -Name $name -MemberType NoteProperty -Value $value
}

ConvertTo-Json $json | Set-Content "$PSScriptRoot/../../temp/state.json"