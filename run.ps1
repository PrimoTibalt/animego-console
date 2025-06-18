[Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::CursorVisible = $false
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
chcp 65001 # UTF-8 code page
Clear-Host
class SelectParameters {
	[ordered]$dictForSelect
	[string]$message
	[bool]$withFallback        = $true
	[bool]$returnKey           = $false
	$preselectedValue
	[bool]$showMessageOnSelect = $true
	[Action[[string],[string]]]$actionOnF
	[Action[[string]]]$actionOnR
	[Func[[string],[string]]]$actionOnEachKey
}

Add-Type -AssemblyName 'System.Net'
Add-Type -Path "$PSScriptRoot/helpers/html_parsers/HtmlAgilityPack.dll"

$menuDict = [ordered]@{
	'Search'="$PSScriptRoot/search_anime.ps1";
	'Choose from watched'="$PSScriptRoot/select_anime_from_watch_list.ps1";
	'Choose from favorites'="$PSScriptRoot/select_anime_from_favorite_list.ps1";
}

$runScriptSelectParameters = New-Object SelectParameters
$runScriptSelectParameters.dictForSelect = $menuDict
$runScriptSelectParameters.withFallback = $false
$runScriptSelectParameters.preselectedValue = 'Choose from favorites'
$runScriptSelectParameters.showMessageOnSelect = $false
while ($true) {
	$menuScriptPath = . "$PSScriptRoot/helpers/select.ps1" $runScriptSelectParameters
	. $menuScriptPath
}
