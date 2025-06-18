$watchedAnimeDict = . "$PSScriptRoot/helpers/watched_management/get_all_watched_dict.ps1"
$watchListSelectParameters = New-Object SelectParameters
$watchListSelectParameters.dictForSelect = $watchedAnimeDict
$watchListSelectParameters.message = 'Select Anime:'
$watchListSelectParameters.returnKey = $true
$watchListSelectParameters.actionOnF = [Action[[string],[string]]]{
	param([string]$addToFavoriteAnimeName, [string]$addToFavoriteAnimeHref)

	$addToFavoriteAnimeHref = "https://animego.one$addToFavoriteAnimeHref"
	. "$PSScriptRoot/helpers/favorite_management/add_new_favorite.ps1" $addToFavoriteAnimeName $addToFavoriteAnimeHref
}
$watchListSelectParameters.actionOnEachKey = [Func[[string],[string]]]{
	param([string]$dictionaryKey)

	$favoriteAnimes = . "$PSScriptRoot/helpers/favorite_management/get_favorites.ps1"

	if ($null -ne $favoriteAnimes[$dictionaryKey]) {
		return '★ ' + $dictionaryKey
	}
	else {
		return $dictionaryKey
	}
}
$watchListSelectParameters.actionOnR = [Action[[string]]]{
	param([string]$removeFromFavoriteAnimeName)

	. "$PSScriptRoot/helpers/favorite_management/remove_favorite.ps1" $removeFromFavoriteAnimeName
}

while ($true) {
	$watchedAnimeName = . "$PSScriptRoot/helpers/select.ps1" $watchListSelectParameters
	if ($fallbackSign -eq $watchedAnimeName) {
		break
	}

	$animeHrefOfSynchronization = . "$PSScriptRoot/helpers/watched_management/synchronize_to_state.ps1" $watchedAnimeName
	. "$PSScriptRoot/select_episode.ps1" $animeHrefOfSynchronization
	Clear-Host
}