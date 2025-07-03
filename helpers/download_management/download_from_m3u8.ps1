param(
	[Parameter(Position = 0)]
	[string]$m3u8UrlToDownloadAFileFrom,
	[Parameter(Position = 1)]
	[string]$pathToSaveDownloadedFile
)

if ([string]::IsNullOrEmpty($pathToSaveDownloadedFile)) {
	$pathToSaveDownloadedFile = "$PSScriptRoot/../../temp/animes/crucible/output/episode.mp4"
}

try {
	ffmpeg --help > $null 2> $null
} catch {
	winget install --id=Gyan.FFmpeg -e
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

if (-not [string]::IsNullOrEmpty($m3u8UrlToDownloadAFileFrom)) {
	$listOfSegments = Invoke-WebRequest -Uri $m3u8UrlToDownloadAFileFrom -UserAgent $agent -Headers @{'Referer' = $referer }
	$linesOfSegments = $listOfSegments.RawContent.Split(',')
	$lastLineOfSegments = $linesOfSegments[$linesOfSegments.Count - 1].Replace('#EXT-X-ENDLIST', [string]::Empty).Replace('./', [string]::Empty).Trim()
	$lastLineOfSegments -match 'seg-(?<countOfSegments>[0-9]*)-' *> $null
	$countOfSegments = [int]::Parse($Matches.countOfSegments)
	$splitUrlOfAnimeManifest = $m3u8UrlToDownloadAFileFrom.Split('/')
	$splitUrlOfAnimeManifest[$splitUrlOfAnimeManifest.Count - 1] = $lastLineOfSegments.Replace($countOfSegments, '{num}')
	$urlToChangePerSegment = [string]::Join('/', $splitUrlOfAnimeManifest)
	for ($i = 1; $i -le $countOfSegments; $i++) {
		$urlForSegment = $urlToChangePerSegment.Replace('{num}', $i)
		Invoke-WebRequest -Uri $urlForSegment -UserAgent $agent -Headers @{'Referer' = $referer } -OutFile "$PSScriptRoot/../../temp/animes/crucible/$i.mp4"
		$percentOfDownload = (([double]::Parse($i) / $countOfSegments)*100).ToString("F1")
		if ($i -ne 1) {
			[Console]::SetCursorPosition(0, $Host.UI.RawUI.CursorPosition.Y-1)
		}
		Write-Host "$percentOfDownload%"
		if ($i -eq 12) {
			break
		}
	}
}

$mp4FilesFromCrucible = Get-ChildItem -Path "$PSScriptRoot/../../temp/animes/crucible" -Filter *.mp4 | Sort-Object CreationTime
$videosEnumerationForFFMPEG = $mp4FilesFromCrucible | ForEach-Object { 'file ' + $_.Name }
Set-Content -Force -Path "$PSScriptRoot/../../temp/animes/crucible/files.txt" -Value $videosEnumerationForFFMPEG
$outputFFMPEGFileName = 'out.mp4'
ffmpeg -f concat -safe 0 -i "$PSScriptRoot/../../temp/animes/crucible/files.txt" -codec copy $outputFFMPEGFileName *> $null;
Move-Item "$PSScriptRoot/$outputFFMPEGFileName" $pathToSaveDownloadedFile -Force
$mp4FilesFromCrucible | ForEach-Object { Remove-Item $_ }