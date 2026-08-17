param(
	[Parameter(Mandatory, Position = 0)]
	[string]$inputTextFromSearchScript
)

[Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
Add-Type -Path "$PSScriptRoot/html_parsers/HtmlAgilityPack.dll"
$encodedSearchText = [Uri]::EscapeDataString($inputTextFromSearchScript)
$queryString = "search/all?q=$encodedSearchText&navbar=true"
$searchResultHtml = . "$PSScriptRoot/try_request.ps1" $queryString

$searchResultContent = [System.Net.WebUtility]::HtmlDecode($searchResultHtml)

$newAnimeToHrefMap = . "$PSScriptRoot/html_parsers/search_anime.ps1" $searchResultContent

$favoriteAnimes = . "$PSScriptRoot/favorite_management/get_favorites.ps1"
foreach ($pair in $newAnimeToHrefMap.GetEnumerator()) {
	$newAnimeName = $pair.Key
	if ($null -ne $favoriteAnimes[$newAnimeName]) {
		$newAnimeName = '★ ' + $newAnimeName
	}

	Write-Host $newAnimeName
	Write-Host $pair.Value
}

Exit
