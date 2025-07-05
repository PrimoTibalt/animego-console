param(
	[Parameter(Position = 0, Mandatory)]
	[string] $blob,
	[Parameter(Position = 1)]
	[string] $referer,
	[Parameter(Position = 2)]
	[bool]$wantToDownload
)

$agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0' 
if ([string]::IsNullOrEmpty($referer)) {
	$referer = 'https://aniboom.one/'
}

$vlc = 'C:\Program Files\VideoLAN\VLC\vlc.exe'

if (-not (Test-Path $vlc)) {
	Write-Host "You don't seem to have VLC player installed, let me change that..."
	winget install --id VideoLAN.VLC --silent
	. "$PSScriptRoot/clean_console.ps1" 10 # Not very reliable ain't it
}

if ($wantToDownload) {
	. "$PSScriptRoot/download_management/download_from_m3u8.ps1" $blob $agent $referer
} else {
	& $vlc --http-referrer $referer --http-user-agent $agent $blob --fullscreen
}