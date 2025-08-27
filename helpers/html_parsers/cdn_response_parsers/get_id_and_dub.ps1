param(
	[Parameter(Mandatory, Position = 0)]
	$cdnIFrameResponseHtml
)

$cdnIFrameResponseDocument = [HtmlAgilityPack.HtmlDocument]::new()
$cdnIFrameResponseDocument.LoadHtml($cdnIFrameResponseHtml)

$cdnVideoPlayerElement = $cdnIFrameResponseDocument.DocumentNode.SelectSingleNode('//video-player')
$cdnVideoPlayerResultData = [PSCustomObject]@{
	AnimeId = $cdnVideoPlayerElement.GetAttributeValue('data-title-id', 0)
	PublisherId = $cdnVideoPlayerElement.GetAttributeValue('data-publisher-id', 0)
	Aggregator = $cdnVideoPlayerElement.GetAttributeValue('data-aggregator', 'mali')
	PriorityDub = $cdnVideoPlayerElement.GetAttributeValue('priority-voice', 'Dream Cast')
}

return $cdnVideoPlayerResultData