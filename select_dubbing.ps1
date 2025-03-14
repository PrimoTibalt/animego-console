param(
	[Parameter(Mandatory, Position = 0)]
	[string]$link,
	[Parameter(Mandatory, Position = 1)]
	$episodeDataId
)

$html = & ./open_player_link.ps1 $link $episodeDataId

$listOfDubs = ./tool/GetEpisodes.exe 'translations' $html
if ($null -eq $listOfDubs) {
	Write-Host 'No dubs available'
	return
}

$dict = [ordered]@{}
foreach ($dub in $listOfDubs.Split(';')) {
	$namePlayersPair = $dub.Split(',')
	$subDict = [ordered]@{}
	foreach ($playerLinkPair in $namePlayersPair[1].Split('||')) {
		$splitted = $playerLinkPair.Split(':')
		$subDict[$splitted[0]] = 'https:' + $splitted[1]
	}

	$dict[$namePlayersPair[0]] = $subDict
}

$players = & ./helpers/select.ps1 $dict 'Select dubber:'
if ($null -ne $players) {
	$link = & ./helpers/select.ps1 $players 'Select player:'
	if ($null -ne $link) {
		& ./watch_episode.ps1 $link
	}
}