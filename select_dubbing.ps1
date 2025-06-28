param(
	[Parameter(Mandatory, Position = 0)]
	[string]$linkToDubbingList,
	[Parameter(Position = 1)]
	$episodeDataId,
	[Parameter(Position = 2)]
	$dubbingListFromMovieHtml
)

if ($null -eq $episodeDataId) {
	$dubbingListHtml = $dubbingListFromMovieHtml
} else {
	$dubbingListHtml = . "$PSScriptRoot/open_player_link.ps1" $linkToDubbingList $episodeDataId
}

$dictOfDubs = . "$PSScriptRoot/helpers/html_parsers/retrieve_translations.ps1" $dubbingListHtml
if ($dictOfDubs.Count -eq 0) {
	. "$PSScriptRoot/helpers/clean_console.ps1" 1
	Write-Host 'No dubs available for selected episode'
	Write-Host '' # Prevent text above from being deleted
	return
}

$selectDubSelectParameters = New-Object SelectParameters
$selectDubSelectParameters.dictForSelect = $dictOfDubs
$selectDubSelectParameters.message = 'Select dubber:'
$selectDubSelectParameters.returnKey = $true
$selectDubSelectParameters.preselectedValue = . "$PSScriptRoot/helpers/state_management/get_dub.ps1"

$selectedDub = . "$PSScriptRoot/helpers/select.ps1" $selectDubSelectParameters
$players = $dictOfDubs.$selectedDub
if ($null -ne $players) {
	. "$PSScriptRoot/helpers/state_management/set_last_dubbing.ps1" $selectedDub

	$selectPlayerSelectParameters = New-Object SelectParameters
	$selectPlayerSelectParameters.dictForSelect = $players
	$selectPlayerSelectParameters.message = 'Select player:'

	$episodeLink = . "$PSScriptRoot/helpers/select.ps1" $selectPlayerSelectParameters
	if (-not [string]::IsNullOrEmpty($episodeLink)) {
		Write-Host "You are watching $episodeLink"
		Write-Host 'Click any button to return '
		if ($episodeLink.Contains('kodik')) {
			. "$PSScriptRoot/watch_kodik.ps1" $episodeLink
		} elseif ($episodeLink.Contains('sibnet')) {
			. "$PSScriptRoot/watch_sibnet.ps1" $episodeLink
		} else {
			. "$PSScriptRoot/watch_aniboom.ps1" $episodeLink
		}

		. "$PSScriptRoot/helpers/watched_management/synchronize_from_state.ps1"
		[Console]::ReadKey($true)
		# clean everything below anime name
		# doesn't know if you went back and forth before starting watching
		. "$PSScriptRoot/helpers/clean_console.ps1" 5
		return 'Seen'
	} else {
		. "$PSScriptRoot/helpers/clean_console.ps1" 1
		return . "$PSScriptRoot/select_dubbing.ps1" $linkToDubbingList $episodeDataId $dubbingListFromMovieHtml
	}
} else {
	return $null
}