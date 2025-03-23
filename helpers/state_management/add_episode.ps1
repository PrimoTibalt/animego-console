param(
	[Parameter(Mandatory, Position = 0)]
	[int]$episodeNumber
)

."$PSScriptRoot/append_property.ps1" 'episode' "$episodeNumber"