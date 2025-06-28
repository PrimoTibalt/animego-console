param(
	[Parameter(Position = 0, Mandatory)]
	[string] $blob,
	[Parameter(Position = 1)]
	[string] $referrer
)

$agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0' 
if ([string]::IsNullOrEmpty($referrer)) {
	$referrer = 'https://aniboom.one/'
}

$vlc = 'C:\Program Files\VideoLAN\VLC\vlc.exe'

if (-not (Test-Path $vlc)) {
	Write-Host "You don't seem to have VLC player installed, let me change that..."
	winget install --id VideoLAN.VLC --silent
	. "$PSScriptRoot/clean_console.ps1" 10 # Not very reliable ain't it
}

& $vlc --http-referrer $referrer --http-user-agent $agent $blob --fullscreen