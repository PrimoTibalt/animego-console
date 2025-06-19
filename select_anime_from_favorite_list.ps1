$fallbackSign = '__'

$favoriteAnimes = . "$PSScriptRoot/helpers/favorite_management/get_favorites.ps1"
$favoriteListSelectParameters = New-Object SelectParameters
$favoriteListSelectParameters.dictForSelect = $favoriteAnimes
$favoriteListSelectParameters.message = 'Select Anime:'
$favoriteListSelectParameters.returnKey = $true
$favoriteListSelectParameters.actionOnF = [Action[[string],[string]]]{
	param([string]$addToFavoriteAnimeName, [string]$addToFavoriteAnimeHref)

	$addToFavoriteAnimeHref = "https://animego.one$addToFavoriteAnimeHref"
	. "$PSScriptRoot/helpers/favorite_management/add_new_favorite.ps1" $addToFavoriteAnimeName $addToFavoriteAnimeHref
}
$favoriteListSelectParameters.actionOnR = [Action[[string]]]{
	param([string]$removeFromFavoriteAnimeName)

	. "$PSScriptRoot/helpers/favorite_management/remove_favorite.ps1" $removeFromFavoriteAnimeName
}

while ($true) {
	$favoriteAnimeName = . "$PSScriptRoot/helpers/select.ps1" $favoriteListSelectParameters
	if ($fallbackSign -eq $favoriteAnimeName) {
		break
	}

	$animeHrefOfSynchronization = . "$PSScriptRoot/helpers/watched_management/synchronize_to_state.ps1" $favoriteAnimeName
	if ([string]::IsNullOrEmpty($animeHrefOfSynchronization)) {
		$animeHrefOfSynchronization = $favoriteAnimes[$favoriteAnimeName]
	}
	. "$PSScriptRoot/select_episode.ps1" $animeHrefOfSynchronization
	Clear-Host
}