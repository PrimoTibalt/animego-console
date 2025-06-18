param(
	[Parameter(Mandatory, Position = 0)]
	[string]$newFavoriteAnimeName,
	[Parameter(Mandatory, Position = 1)]
	[string]$newFavoriteAnimeHref
)

$favoriteAnimesFilePath = "$PSScriptRoot/../../temp/favorites.json"
if (-not (Test-Path -Path $favoriteAnimesFilePath)) {
	New-Item -Path $favoriteAnimesFilePath -ItemType File -Value '{}' -Force > $null
}

$favoriteAnimes = . "$PSScriptRoot/get_favorites.ps1"

$favoriteAnimes[$newFavoriteAnimeName] = $newFavoriteAnimeHref
$updatedFavoritesJson = ConvertTo-Json $favoriteAnimes
Set-Content -Path $favoriteAnimesFilePath -Value $updatedFavoritesJson