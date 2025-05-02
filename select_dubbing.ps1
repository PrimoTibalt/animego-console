param(
	[Parameter(Mandatory, Position = 0)]
	[string]$linkToDubbingList,
	[Parameter(Mandatory, Position = 1)]
	$episodeDataId
)

$dubbingListHtml = . "$PSScriptRoot/open_player_link.ps1" $linkToDubbingList $episodeDataId

try {
	$listOfDubs = . "$PSScriptRoot/tool/GetEpisodes.exe" 'translations' $dubbingListHtml 2> "$PSScriptRoot/temp/log.txt"
} catch {
	Set-Content "$PSScriptRoot/tool/translations.html" $dubbingListHtml
	$listOfDubs = . "$PSScriptRoot/tool/GetEpisodes.exe" 'translations' 2> "$PSScriptRoot/temp/log.txt"
}

if ($null -eq $listOfDubs) {
	. "$PSScriptRoot/helpers/clean_console.ps1" 1
	Write-Host 'No dubs available for selected episode'
	Write-Host ""	# Prevent text above from being deleted
	return
}

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

$preselectedDub = . "$PSScriptRoot/helpers/state_management/get_dub.ps1"
$selectedDub = . "$PSScriptRoot/helpers/select.ps1" $dictOfDubs 'Select dubber:' $true $true $preselectedDub
$players = $dictOfDubs.$selectedDub
if ($null -ne $players) {
	. "$PSScriptRoot/helpers/state_management/set_last_dubbing.ps1" $selectedDub
	$episodeLink = . "$PSScriptRoot/helpers/select.ps1" $players 'Select player:'
	if (-not [string]::IsNullOrEmpty($episodeLink)) {
		Write-Host "You are watching $episodeLink"
		Write-Host 'Click any button to return '
		. "$PSScriptRoot/watch_episode.ps1" $episodeLink
		. "$PSScriptRoot/helpers/watched_management/synchronize_from_state.ps1"
		[Console]::ReadKey($true)
		# clean everything below anime name
		# doesn't know if you went back and forth before starting watching
		. "$PSScriptRoot/helpers/clean_console.ps1" 5
		return 'Seen'
	} else {
		. "$PSScriptRoot/helpers/clean_console.ps1" 1
		return . "$PSScriptRoot/select_dubbing.ps1" $linkToDubbingList $episodeDataId
	}
} else {
	return $null
}