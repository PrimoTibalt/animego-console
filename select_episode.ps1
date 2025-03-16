param(
	[Parameter(Mandatory, Position = 0)]
	[string]$link,
	[Parameter(Position = 1)]
	[System.Collections.Specialized.OrderedDictionary]$dict
)

Add-Type -AssemblyName 'System.Net'
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding

$html = ./open_player_link.ps1 $link
if ($null -eq $html) {
	Write-Host 'Unable to fetch player link, site is down or antiddos kicked in'
	return
}

$episodes = ./tool/GetEpisodes.exe 'episodes' $html 2> ./temp/log.txt
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

$preselectedEpisode = ./helpers/state_management/get_episode.ps1
$episodeNumber = ./helpers/select.ps1 $dict 'Select episode:' $true $true $preselectedEpisode
$dataId = $dict.$episodeNumber
if ($null -ne $dataId) {
	./helpers/state_management/add_episode.ps1 $episodeNumber
	./select_dubbing.ps1 $link $dataId
	./helpers/clean_console.ps1 1
	./select_episode.ps1 $link
} else {
	return $null
}