param(
	[Parameter(Mandatory, Position = 0)]
	$htmlStringToGetEpisodes
)

$htmlDocumentToGetEpisodes = [HtmlAgilityPack.HtmlDocument]::new()
$htmlDocumentToGetEpisodes.LoadHtml($htmlStringToGetEpisodes)

$getEpisodesResultMap = [ordered]@{}
$episodesNodes = $htmlDocumentToGetEpisodes.DocumentNode.SelectNodes('//option[@value]')
for ($i = 0; $i -lt $episodesNodes.Count; $i++) {
	$episodeNode = $episodesNodes[$i]
	$episodeNodeNumber = $episodeNode.InnerText.Split(' ')[0]
	$episodeNodeDataId = $episodeNode.GetAttributeValue('value', [string]::Empty)
	$getEpisodesResultMap[$episodeNodeNumber] = $episodeNodeDataId
}

return $getEpisodesResultMap