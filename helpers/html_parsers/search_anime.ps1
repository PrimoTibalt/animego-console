param(
	[Parameter(Mandatory, Position = 0)]
	$htmlStringToSearchAnime
)

$htmlDocumentToSearchAnime = [HtmlAgilityPack.HtmlDocument]::new()
$htmlDocumentToSearchAnime.LoadHtml($htmlStringToSearchAnime)
$animeSectionSelector = "//a[starts-with(@href,'/search/anime')]/ancestor::div[contains(@class,'mw-0')][1]"
$animeSectionNode = $htmlDocumentToSearchAnime.DocumentNode.SelectSingleNode($animeSectionSelector)
if ($null -eq $animeSectionNode) {
	return [ordered]@{}
}

$animeNodes = $animeSectionNode.SelectNodes(".//a[contains(@class,'ajax-search__item')]")
if ($null -eq $animeNodes) {
	return [ordered]@{}
}

$searchAnimeResultMap = [ordered]@{}
for ($i = 0; $i -lt $animeNodes.Count; $i++) {
	$animeNode = $animeNodes[$i]
	$animeNodeHref = $animeNode.GetAttributeValue('href', [string]::Empty).Trim()
	if (-not $animeNodeHref.StartsWith('/anime/')) {
		continue
	}

	$animeTitleNode = $animeNode.SelectSingleNode(".//*[contains(@class,'ajax-search__item-title')]")
	if ($null -eq $animeTitleNode) {
		continue
	}

	$animeNodeName = [System.Net.WebUtility]::HtmlDecode($animeTitleNode.InnerText).Trim()
	if ([string]::IsNullOrEmpty($animeNodeName)) {
		continue
	}

	$searchAnimeResultMap[$animeNodeName] = $animeNodeHref
}

return $searchAnimeResultMap
