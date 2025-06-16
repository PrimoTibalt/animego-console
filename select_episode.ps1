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
		$Host.UI.RawUI.ReadKey()
		return
	}

	$dictOfEpisodes = . "$PSScriptRoot/helpers/html_parsers/retrieve_episodes.ps1" $fetchEpisodesResultHtml
	if ($dictOfEpisodes.Count -eq 0) {
		Write-Host 'No episodes found'
		$Host.UI.RawUI.ReadKey()
		return
	}
}

$preselectedEpisode = . "$PSScriptRoot/helpers/state_management/get_episode.ps1"

$selectEpisodeSelectParameters = New-Object SelectParameters
$selectEpisodeSelectParameters.dictForSelect = $dictOfEpisodes
$selectEpisodeSelectParameters.returnKey = $true
$selectEpisodeSelectParameters.message = 'Select episode:'
$selectEpisodeSelectParameters.preselectedValue = $preselectedEpisode

$episodeNumber = . "$PSScriptRoot/helpers/select.ps1" $selectEpisodeSelectParameters
$dataId = $dictOfEpisodes.$episodeNumber
if ($null -ne $dataId) {
	. "$PSScriptRoot/helpers/state_management/add_episode.ps1" $episodeNumber
	. "$PSScriptRoot/select_dubbing.ps1" $fetchEpisodesLink $dataId
	. "$PSScriptRoot/helpers/clean_console.ps1" 1
	. "$PSScriptRoot/select_episode.ps1" $fetchEpisodesLink $dictOfEpisodes
} else {
	return $null
}