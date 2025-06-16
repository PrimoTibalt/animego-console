$watchedAnimeDict = . "$PSScriptRoot/helpers/watched_management/get_all_watched_dict.ps1"
$watchListSelectParameters = New-Object SelectParameters
$watchListSelectParameters.dictForSelect = $watchedAnimeDict
$watchListSelectParameters.message = 'Select Anime:'
$watchListSelectParameters.returnKey = $true
while ($true) {
	$watchedAnimeName = . "$PSScriptRoot/helpers/select.ps1" $watchListSelectParameters
	if ($fallbackSign -eq $watchedAnimeName) {
		break
	}

	$animeHrefOfSynchronization = . "$PSScriptRoot/helpers/watched_management/synchronize_to_state.ps1" $watchedAnimeName
	. "$PSScriptRoot/select_episode.ps1" $animeHrefOfSynchronization
	Clear-Host
}