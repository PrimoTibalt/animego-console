$allWatchedAnime = Get-Content "$PSScriptRoot/../../temp/global.json" | ConvertFrom-Json;

$animeProperties = Get-Member -InputObject $allWatchedAnime -MemberType NoteProperty
$allWatchedAnimeDict = [ordered]@{}
foreach($animeProperty in $animeProperties) {
	$animeName = $animeProperty.Name
	$allWatchedAnimeDict[$animeName] = $allWatchedAnime.$animeName
}

return $allWatchedAnimeDict