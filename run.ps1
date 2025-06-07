[Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
chcp 65001 # UTF-8 code page
Clear-Host

Add-Type -AssemblyName 'System.Net'

$menuDict = [ordered]@{
	'Search'="$PSScriptRoot/search_anime.ps1";
	'Choose from watched'="$PSScriptRoot/select_anime_from_watch_list.ps1";
}

while ($true) {
	$menuScriptPath = . "$PSScriptRoot/helpers/select.ps1" $menuDict '' $false $false 'Choose from watched' $false
	. $menuScriptPath
}
