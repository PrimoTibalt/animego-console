param(
	[Parameter(Mandatory, Position = 0)]
	[string]$inputTextFromSearchScript,
	[Parameter(Mandatory, Position = 1)]
	$foundAnimeToHrefMap,
	[Parameter(Position = 2)]
	[string]$rememberMeToken,
	[Parameter(Position = 3)]
	[System.Threading.CancellationToken]$token
)

$queryString = "search/all?type=small&q=$inputTextFromSearchScript&_=1741983593650"
$rememberMeCookie = "REMEMBERME=$rememberMeToken"
$searchResultHtml = . "$PSScriptRoot/try_request.ps1" $queryString $null $rememberMeCookie $token

if ($token.IsCancellationRequested) {
	return $foundAnimeToHrefMap
}

[Console]::SetCursorPosition(0, $foundAnimeToHrefMap.Count + 2)
. "$PSScriptRoot/clean_console.ps1" ($foundAnimeToHrefMap.Count + 1)
$searchResultContent = [System.Net.WebUtility]::HtmlDecode($searchResultHtml)

$newAnimeToHrefMap = . "$PSScriptRoot/html_parsers/search_anime.ps1" $searchResultContent

if ($token.IsCancellationRequested) {
	return $foundAnimeToHrefMap
}

[Console]::SetCursorPosition(0, 1);
$favoriteAnimes = . "$PSScriptRoot/favorite_management/get_favorites.ps1"
foreach ($pair in $newAnimeToHrefMap.GetEnumerator()) {
	$newAnimeName = $pair.Key
	if ($null -ne $favoriteAnimes[$newAnimeName]) {
		$newAnimeName = '★ ' + $newAnimeName
	}

	Write-Host $newAnimeName
}

[Console]::SetCursorPosition($inputTextFromSearchScript.Length, 0)
return $newAnimeToHrefMap
