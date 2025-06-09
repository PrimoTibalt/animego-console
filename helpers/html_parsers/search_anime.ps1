param(
	[Parameter(Mandatory, Position = 0)]
	$htmlStringToSearchAnime
)

$htmlDocumentToSearchAnime = [HtmlAgilityPack.HtmlDocument]::new()
$htmlDocumentToSearchAnime.LoadHtml($htmlStringToSearchAnime)
$animeNodes = $htmlDocumentToSearchAnime.DocumentNode.SelectNodes("//div[@class='result-search-anime']/div/div/h5/a")
if ($null -eq $animeNodes) {
	$animeNodes = [HtmlAgilityPack.HtmlNodeCollection]::new()
}

$searchAnimeResultMap = [ordered]@{}
for ($i = 0; $i -lt $animeNodes.Count; $i++) {
	$animeNode = $animeNodes[$i]
	$animeNodeHref = $animeNode.GetAttributeValue('href', [string]::Empty).Trim()
	$animeNodeName = $animeNode.InnerText.Trim()
	$searchAnimeResultMap[$animeNodeName] = $animeNodeHref
}

return $searchAnimeResultMap