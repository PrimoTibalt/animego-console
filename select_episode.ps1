param(
	[Parameter(Mandatory, Position = 0)]
	[string]$fetchEpisodesLink,
	[Parameter(Position = 1)]
	[System.Collections.Specialized.OrderedDictionary]$dictOfEpisodes
)

if ($null -eq $dictOfEpisodes) {
	Add-Type -AssemblyName 'System.Net'

	$fetchEpisodesResultHtml = . "$PSScriptRoot/open_player_link.ps1" $fetchEpisodesLink
	if ($null -eq $fetchEpisodesResultHtml) {
		Write-Host 'Unable to fetch player link, site is down or antiddos kicked in'
		return
	}

	try {
		$episodes = . "$PSScriptRoot/tool/GetEpisodes.exe" 'episodes' $fetchEpisodesResultHtml 2> "$PSScriptRoot/temp/log.txt"
	} catch {
		Set-Content "$PSScriptRoot/tool/episodes.html" $fetchEpisodesResultHtml
		$episodes = . "$PSScriptRoot/tool/GetEpisodes.exe" 'episodes' 2> "$PSScriptRoot/temp/log.txt"
	}

	if ([string]::IsNullOrEmpty($episodes)) {
		Write-Host 'No episodes found'
		return
	}

	$episodes = $episodes.Split(';')
	if ($episodes.Count -lt 0) {
		Write-Error 'No episodes found'
		return $null
	}

	$dictOfEpisodes = [ordered]@{}
	foreach ($episode in $episodes) {
		$pair = $episode.Split(',')
		$key = $pair[0].Trim()
		$value = $pair[1].Trim()
		$dictOfEpisodes.Add($key, $value)
	}
}

$preselectedEpisode = . "$PSScriptRoot/helpers/state_management/get_episode.ps1"
$episodeNumber = . "$PSScriptRoot/helpers/select.ps1" $dictOfEpisodes 'Select episode:' $true $true $preselectedEpisode
$dataId = $dictOfEpisodes.$episodeNumber
if ($null -ne $dataId) {
	. "$PSScriptRoot/helpers/state_management/add_episode.ps1" $episodeNumber
	. "$PSScriptRoot/select_dubbing.ps1" $fetchEpisodesLink $dataId
	. "$PSScriptRoot/helpers/clean_console.ps1" 1
	. "$PSScriptRoot/select_episode.ps1" $fetchEpisodesLink $dictOfEpisodes
} else {
	return $null
}