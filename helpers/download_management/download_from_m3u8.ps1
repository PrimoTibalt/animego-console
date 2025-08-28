param(
	[Parameter(Position = 0)]
	[string]$m3u8UrlToDownloadAFileFrom,
	[Parameter(Position = 1)]
	[string]$userAgent,
	[Parameter(Position = 2)]
	[string]$referer
)

$listOfSubstitution = @{
	'/' = '@#'
	'\' = '@;'
	':' = '@&'
	'?' = '@*'
	'"' = '#@'
	'<' = ';@'
	'>' = '&@'
	'|' = '*@'
}

$animeState = . "$PSScriptRoot/../state_management/get_state.ps1"
$animeNameFromState = $animeState.name
foreach ($substitutionPair in $listOfSubstitution.GetEnumerator()) {
	$animeNameFromState = $animeNameFromState.Replace($substitutionPair.Key, $substitutionPair.Value)
}

$animeEpisodeFromState = $animeState.episode
$animeDubFromState = $animeState.dub

$pathToSaveDownloadedFile = "$PSScriptRoot/../../temp/animes/$animeNameFromState/$animeDubFromState/$animeEpisodeFromState.mp4"
$pathToSaveLinkToAnime = "$PSScriptRoot/../../temp/animes/$animeNameFromState/href.txt"

. "$PSScriptRoot/download_ffmpeg.ps1"

Write-Host 'Episode is being loaded'
$tempVideoFilePath = "$PSScriptRoot/file.mp4"
if (Test-Path $tempVideoFilePath) {
	Remove-Item $tempVideoFilePath
}

ffmpeg -user_agent $userAgent -headers "Referer: $referer" -i $m3u8UrlToDownloadAFileFrom -c copy -crf 50 $tempVideoFilePath *> $null
try {
	New-Item $pathToSaveDownloadedFile -Force
	Move-Item $tempVideoFilePath $pathToSaveDownloadedFile -Force
	$currentStateOfProgram = . "$PSScriptRoot/../state_management/get_state.ps1"
	Set-Content $pathToSaveLinkToAnime $currentStateOfProgram.href -Force
	Write-Host 'Episode is ready'
} catch {
	Write-Host 'There were problems during downloading... Sorry...'
} finally {
	[Console]::Beep()
}

return $pathToSaveDownloadedFile