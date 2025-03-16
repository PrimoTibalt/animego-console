param(
	[Parameter(Mandatory, Position = 0)]
	[int]$episodeNumber
)

./helpers/state_management/append_property.ps1 "episode" "$episodeNumber"