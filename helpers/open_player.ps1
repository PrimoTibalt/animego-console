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

if ($wantToDownload) {
	. "$PSScriptRoot/download_management/download_from_m3u8.ps1" $blob $agent $referer
	return
}

if ($useFfplay) {
	. "$PSScriptRoot/download_management/download_ffmpeg.ps1"

	ffplay -i $blob -user_agent $agent -headers "Referer: $referer" -fs *> $null
	return
}

$vlc = . "$PSScriptRoot/platform_management/get_vlc_path.ps1"
if ($null -eq $vlc) {
	. "$PSScriptRoot/download_management/download_vlc.ps1"
	$vlc = . "$PSScriptRoot/platform_management/get_vlc_path.ps1"
}

if ($null -eq $vlc) {
	Write-Host 'VLC player was not found, nothing to play it with. Click any button to return'
	[Console]::ReadKey($true) > $null
	. "$PSScriptRoot/clean_console.ps1" 1
	return
}

& $vlc --http-referrer $referer --http-user-agent $agent $blob --fullscreen *> $null
