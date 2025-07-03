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
$mp4FilesFromCrucible | ForEach-Object {
	$mp4FilePath = "$PSScriptRoot/../../temp/animes/crucible/" + $_.Name
	$tsFilePath = $_.Name.Replace('.mp4', '.ts')
	ffmpeg -i $mp4FilePath -c copy -bsf:v h264_mp4toannexb -f mpegts $tsFilePath *> $null
	}
$tsFilesFromCrucible = Get-ChildItem -Path $PSScriptRoot -Filter *.ts | Sort-Object CreationTime
$longTsString = [string]::Join('|', $tsFilesFromCrucible)
$outputFFMPEGFileName = 'out.mp4'
ffmpeg -f mpegts -i "concat:$longTsString" -c copy -crf 50 $outputFFMPEGFileName *> $null;
New-Item $pathToSaveDownloadedFile -Force *> $null
Move-Item "$PSScriptRoot/$outputFFMPEGFileName" $pathToSaveDownloadedFile -Force *> $null
$mp4FilesFromCrucible | ForEach-Object { Remove-Item $_ }
$tsFilesFromCrucible | ForEach-Object { Remove-Item $_ }