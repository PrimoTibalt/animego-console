param(
	[Parameter(Mandatory, Position = 0)]
	$exFavoriteAnimeName
)

$favoriteAnimesFilePath = "$PSScriptRoot/../../temp/favorites.json"

if (-not (Test-Path -Path $favoriteAnimesFilePath)) {
	New-Item -Path $favoriteAnimesFilePath -ItemType File -Value '{}' -Force > $null
}

$favoriteAnimes = . "$PSScriptRoot/get_favorites.ps1"

$favoriteAnimes.Remove($exFavoriteAnimeName)
$updatedFavoritesJson = ConvertTo-Json $favoriteAnimes
Set-Content -Path $favoriteAnimesFilePath -Value $updatedFavoritesJson