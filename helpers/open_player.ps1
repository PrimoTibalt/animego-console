param(
	[Parameter(Position = 0, Mandatory)]
	[string] $blob,
	[Parameter(Position = 1)]
	[string] $referer,
	[Parameter(Position = 2)]
	[bool] $wantToDownload,
	[Parameter(Position = 3)]
	[bool] $useFfplay
)

$agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0' 
if ([string]::IsNullOrEmpty($referer)) {
	$referer = 'https://aniboom.one/'
}

$vlcDefaultPath = 'C:\Program Files\VideoLAN\VLC\vlc.exe'
$vlcX86Path = 'C:\Program Files (x86)\VideoLAN\VLC\vlc.exe'

if ((-not (Test-Path $vlcDefaultPath)) -and (-not (Test-Path $vlcX86Path)) -and (-not $useFfplay)) {
	. "$PSScriptRoot/download_management/download_vlc.ps1"
}

if ($wantToDownload) {
	. "$PSScriptRoot/download_management/download_from_m3u8.ps1" $blob $agent $referer
} elseif ($useFfplay) {
	. "$PSScriptRoot/download_management/download_ffmpeg.ps1"

	ffplay -i $blob -user_agent $agent -headers "Referer: $referer" -fs *> $null
} else {
	if (Test-Path $vlcDefaultPath) {
		$vlc = $vlcDefaultPath
	} else {
		$vlc = $vlcX86Path
	}

	& $vlc --http-referrer $referer --http-user-agent $agent $blob --fullscreen
}