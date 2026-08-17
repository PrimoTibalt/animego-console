param(
	[Parameter(Mandatory, Position = 0)]
	$htmlStringToGetEpisodes
)

$htmlDocumentToGetEpisodes = [HtmlAgilityPack.HtmlDocument]::new()
$htmlDocumentToGetEpisodes.LoadHtml($htmlStringToGetEpisodes)

$getEpisodesResultMap = [ordered]@{}
$episodesNodes = $htmlDocumentToGetEpisodes.DocumentNode.SelectNodes('//*[@data-episode][@data-episode-number]')
if ($null -eq $episodesNodes) {
	return $getEpisodesResultMap
}

for ($i = 0; $i -lt $episodesNodes.Count; $i++) {
	$episodeNode = $episodesNodes[$i]
	$episodeNodeNumber = $episodeNode.GetAttributeValue('data-episode-number', [string]::Empty).Trim()
	$episodeNodeDataId = $episodeNode.GetAttributeValue('data-episode', [string]::Empty).Trim()
	if ([string]::IsNullOrEmpty($episodeNodeNumber) -or [string]::IsNullOrEmpty($episodeNodeDataId)) {
		continue
	}

	if ($getEpisodesResultMap.Contains($episodeNodeNumber)) {
		continue
	}

	$getEpisodesResultMap[$episodeNodeNumber] = $episodeNodeDataId
}

return $getEpisodesResultMap
