param(
	[Parameter(Mandatory, Position = 0)]
	[string]$link,
	[Parameter(Mandatory, Position = 1)]
	$episodeDataId
)

$html = ./open_player_link.ps1 $link $episodeDataId

$listOfDubs = ./tool/GetEpisodes.exe 'translations' $html 2> ./temp/log.txt
if ($null -eq $listOfDubs) {
	./helpers/clean_console.ps1 1
	Write-Host 'No dubs available for selected episode'
	# Prevent text above from being deleted
	Write-Host ""
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

$preselectedDub = ./helpers/state_management/get_dub.ps1
$selectedDub = ./helpers/select.ps1 $dict 'Select dubber:' $true $true $preselectedDub
$players = $dict.$selectedDub
if ($null -ne $players) {
	./helpers/state_management/set_last_dubbing.ps1 $selectedDub
	$episodeLink = ./helpers/select.ps1 $players 'Select player:'
	if (-not [string]::IsNullOrEmpty($episodeLink)) {
		Write-Host "You are watching $episodeLink"
		Write-Host 'Click any button to return '
		./watch_episode.ps1 $episodeLink
		[Console]::ReadKey($true)
		# clean everything below anime name
		# doesn't know if you went back and forth before starting watching
		./helpers/clean_console.ps1 6
		return 'Seen'
	} else {
		./helpers/clean_console.ps1 1
		./select_dubbing.ps1 $link $episodeDataId
	}
} else {
	return $null
}