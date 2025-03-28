param(
	[Parameter(Mandatory, Position = 0)]
	[string]$state
)

Set-Content "$PSScriptRoot/../../temp/state.json" $state