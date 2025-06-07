param(
	[Parameter(Position = 0, Mandatory)]
	[System.Collections.Specialized.OrderedDictionary]$dictForSelect,
	[Parameter(Position = 1)]
	[string]$message,
	[Parameter(Position = 2)]
	[bool]$withFallback = $true,
	[Parameter(Position = 3)]
	[bool]$returnKey = $false,
	[Parameter(Position = 4)]
	$preselectedValue,
	[Parameter(Position = 5)]
	[bool]$showMessageOnSelect = $true
)

. "$PSScriptRoot/extended_select/multipage_extension.ps1" $dictForSelect $message $withFallback $returnKey $preselectedValue $showMessageOnSelect