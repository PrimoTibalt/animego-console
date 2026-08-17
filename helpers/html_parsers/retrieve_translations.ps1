param(
	[Parameter(Mandatory, Position = 0)]
	$htmlStringToGetTranslations
)

$getTranslationsResultMap = [ordered]@{}
if ([string]::IsNullOrEmpty($htmlStringToGetTranslations)) {
	return $getTranslationsResultMap
}

$htmlDocumentToGetTranslations = [HtmlAgilityPack.HtmlDocument]::new()
$htmlDocumentToGetTranslations.LoadHtml($htmlStringToGetTranslations)

$providerNodes = $htmlDocumentToGetTranslations.DocumentNode.SelectNodes('//*[@data-player][@data-translation-title]')
if ($null -eq $providerNodes) {
	return $getTranslationsResultMap
}

for ($providerNodeIndex = 0; $providerNodeIndex -lt $providerNodes.Count; $providerNodeIndex++) {
	$providerNode = $providerNodes[$providerNodeIndex]

	$translationName = [System.Net.WebUtility]::HtmlDecode($providerNode.GetAttributeValue('data-translation-title', [string]::Empty)).Trim()
	$playerNodeName = [System.Net.WebUtility]::HtmlDecode($providerNode.GetAttributeValue('data-provider-title', [string]::Empty)).Trim()
	$playerNodeHref = [System.Net.WebUtility]::HtmlDecode($providerNode.GetAttributeValue('data-player', [string]::Empty)).Trim()

	if ([string]::IsNullOrEmpty($translationName) -or [string]::IsNullOrEmpty($playerNodeName) -or [string]::IsNullOrEmpty($playerNodeHref)) {
		continue
	}

	if ($playerNodeHref.StartsWith('//')) {
		$playerNodeHref = "https:$playerNodeHref"
	}

	if (-not $getTranslationsResultMap.Contains($translationName)) {
		$getTranslationsResultMap[$translationName] = [ordered]@{}
	}

	$getTranslationsResultMap[$translationName][$playerNodeName] = $playerNodeHref
}

return $getTranslationsResultMap
