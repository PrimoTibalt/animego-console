param(
	[Parameter(Mandatory, Position = 0)]
	[string]$dubName
)

./helpers/state_management/append_property.ps1 "dub" $dubName