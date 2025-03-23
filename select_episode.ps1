param(
	[Parameter(Mandatory, Position = 0)]
	[string]$link,
	[Parameter(Position = 1)]
	[System.Collections.Specialized.OrderedDictionary]$dict
)

Add-Type -AssemblyName 'System.Net'

$html = . "$PSScriptRoot/open_player_link.ps1" $link
if ($null -eq $html) {
	Write-Host 'Unable to fetch player link, site is down or antiddos kicked in'
	return
}

$episodes = . "$PSScriptRoot/tool/GetEpisodes.exe" 'episodes' $html 2> ./temp/log.txt
if ([string]::IsNullOrEmpty($episodes)) {
	Write-Host 'No episodes found'
	return
}

$episodes = $episodes.Split(';')
if ($episodes.Count -lt 0) {
	Write-Error 'No episodes found'
	return $null
}

$dict = [ordered]@{}
foreach ($episode in $episodes) {
	$pair = $episode.Split(',')
	$key = $pair[0].Trim()
	$value = $pair[1].Trim()
	$dict.Add($key, $value)
}

$preselectedEpisode = . "$PSScriptRoot/helpers/state_management/get_episode.ps1"
$episodeNumber = . "$PSScriptRoot/helpers/select.ps1" $dict 'Select episode:' $true $true $preselectedEpisode
$dataId = $dict.$episodeNumber
if ($null -ne $dataId) {
	. "$PSScriptRoot/helpers/state_management/add_episode.ps1" $episodeNumber
	. "$PSScriptRoot/select_dubbing.ps1" $link $dataId
	. "$PSScriptRoot/helpers/clean_console.ps1" 1
	. "$PSScriptRoot/select_episode.ps1" $link
} else {
	return $null
}