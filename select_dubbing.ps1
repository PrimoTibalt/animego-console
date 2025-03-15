param(
	[Parameter(Mandatory, Position = 0)]
	[string]$link,
	[Parameter(Mandatory, Position = 1)]
	$episodeDataId
)

$html = ./open_player_link.ps1 $link $episodeDataId

$listOfDubs = ./tool/GetEpisodes.exe 'translations' $html 2> ./temp/log.txt
if ($null -eq $listOfDubs) {
	Write-Host 'No dubs available'
	return
}

$dict = [ordered]@{}
foreach ($dub in $listOfDubs.Split(';')) {
	$namePlayersPair = $dub.Split(',')
	$subDict = [ordered]@{}
	foreach ($playerLinkPair in $namePlayersPair[1].Split('||')) {
		if (-not [string]::IsNullOrEmpty($playerLinkPair)) {
			$splitted = $playerLinkPair.Split(':')
			$subDict[$splitted[0]] = 'https:' + $splitted[1]
		}
	}

	$dict[$namePlayersPair[0]] = $subDict
}

$players = ./helpers/select.ps1 $dict 'Select dubber:'
if ($null -ne $players) {
	$episodeLink = ./helpers/select.ps1 $players 'Select player:'
	if ($null -ne $link) {
		Write-Host "You are watching $episodeLink"
		Write-Host 'Click any button to return '
		./watch_episode.ps1 $episodeLink
		[Console]::ReadKey($true)
	}
}