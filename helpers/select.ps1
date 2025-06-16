param(
	[Parameter(Position = 0, Mandatory)]
	[SelectParameters]$selectParameters
)

. "$PSScriptRoot/extended_select/multipage_extension.ps1" $selectParameters