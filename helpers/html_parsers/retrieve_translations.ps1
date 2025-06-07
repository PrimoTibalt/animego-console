param(
	[Parameter(Mandatory, Position = 0)]
	$htmlStringToGetTranslations
)

$htmlDocumentToGetTranslations = [HtmlAgilityPack.HtmlDocument]::new()
$htmlDocumentToGetTranslations.LoadHtml($htmlStringToGetTranslations)

$getTranslationsResultMap = [ordered]@{}
$translationsNodes = $htmlDocumentToGetTranslations.DocumentNode.SelectNodes("//div[@id='video-dubbing']/span[@data-dubbing]")
for ($i = 0; $i -lt $translationsNodes.Count; $i++) {
	$translationNode = $translationsNodes[$i]
	$translationName = $translationNode.SelectSingleNode('child::span').InnerText.Trim()
	$translationDubbingId = $translationNode.GetAttributeValue('data-dubbing', 0)
	$translationDubbingPlayersSelector = "//div[@id='video-players']/span[@data-provide-dubbing='$translationDubbingId']"
	$translationElementsWithPlayers = $htmlDocumentToGetTranslations.DocumentNode.SelectNodes($translationDubbingPlayersSelector)
	$playersSubDictionary = [ordered]@{}
	for ($playerNodeIndex = 0; $playerNodeIndex -lt $translationElementsWithPlayers.Count; $playerNodeIndex++) {
		$playerNode = $translationElementsWithPlayers[$playerNodeIndex]
		$playerNodeName = $playerNode.SelectSingleNode('child::span').InnerText.Trim()
		$playerNodeHref = [System.Net.WebUtility]::HtmlDecode($playerNode.GetAttributeValue('data-player', [string]::Empty))
		$playerNodeUrl = "https:$playerNodeHref"
		$playersSubDictionary[$playerNodeName] = $playerNodeUrl
	}

	$getTranslationsResultMap[$translationName] = $playersSubDictionary
}

return $getTranslationsResultMap

$dictOfDubs = [ordered]@{}
foreach ($dub in $listOfDubs.Split(';')) {
	$namePlayersPair = $dub.Split(',')
	$subDict = [ordered]@{}
	foreach ($playerLinkPair in $namePlayersPair[1].Split('||')) {
		if (-not [string]::IsNullOrEmpty($playerLinkPair)) {
			$splitted = $playerLinkPair.Split(':')
			$subDict[$splitted[0]] = 'https:' + $splitted[1]
		}
	}

	$dictOfDubs[$namePlayersPair[0]] = $subDict
}