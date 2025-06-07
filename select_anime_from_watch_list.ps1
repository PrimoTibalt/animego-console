while ($true) {
	$watchedAnimeDict = . "$PSScriptRoot/helpers/watched_management/get_all_watched_dict.ps1"
	$watchedAnimeName = . "$PSScriptRoot/helpers/select.ps1" $watchedAnimeDict 'Select Anime:' $true $true
	if ($fallbackSign -eq $watchedAnimeName) {
		break
	}

	$animeHrefOfSynchronization = . "$PSScriptRoot/helpers/watched_management/synchronize_to_state.ps1" $watchedAnimeName
	. "$PSScriptRoot/select_episode.ps1" $animeHrefOfSynchronization
	Clear-Host
}