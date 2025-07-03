param(
	[Parameter(Position = 0)]
	[string]$m3u8UrlToDownloadAFileFrom,
	[Parameter(Position = 1)]
	[string]$userAgent,
	[Parameter(Position = 2)]
	[string]$referer
)

$animeState = . "$PSScriptRoot/../state_management/get_state.ps1"
$animeNameFromState = $animeState.name
$animeEpisodeFromState = $animeState.episode

$pathToSaveDownloadedFile = "$PSScriptRoot/../../temp/animes/$animeNameFromState/$animeEpisodeFromState.mp4"

try {
	ffmpeg --help > $null 2> $null
} catch {
	winget install --id=Gyan.FFmpeg -e
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

Write-Host 'Episode is being loaded'
$tempVideoFilePath = "$PSScriptRoot/file.mp4"
ffmpeg -user_agent $userAgent -headers "Referer: $referer" -i $m3u8UrlToDownloadAFileFrom -c copy -crf 50 $tempVideoFilePath *> $null
New-Item $pathToSaveDownloadedFile -Force
Move-Item $tempVideoFilePath $pathToSaveDownloadedFile -Force
Write-Host 'Episode is ready'