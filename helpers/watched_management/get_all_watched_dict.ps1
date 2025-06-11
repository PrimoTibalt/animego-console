$globalStatePath = "$PSScriptRoot/../../temp/global.json" 
$allWatchedAnimeDict = [ordered]@{}
if (-not (Test-Path $globalStatePath)) {
	return $allWatchedAnimeDict
}
$allWatchedAnime = Get-Content -Path $globalStatePath | ConvertFrom-Json

$animeProperties = Get-Member -InputObject $allWatchedAnime -MemberType NoteProperty
foreach($animeProperty in $animeProperties) {
	$animeName = $animeProperty.Name
	$allWatchedAnimeDict[$animeName] = $allWatchedAnime.$animeName
}

return $allWatchedAnimeDict