param(
	[Parameter(Mandatory, Position = 0)]
	[string]$dubName
)

. "$PSScriptRoot/append_property.ps1" 'dub' $dubName