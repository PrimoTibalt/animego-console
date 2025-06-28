param(
	[Parameter(Mandatory, Position = 0)]
	[string]$sibnetShellEpisodeLink
)

$sibnetEpisodePlayerHeaders = @{
	'Referer'        = 'https://animego.one/'
	'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0'
	'Accept'         = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7'
}

$sibnetShellResponse = Invoke-RestMethod -Uri $sibnetShellEpisodeLink -Headers $sibnetEpisodePlayerHeaders
$sibnetShellResponse -match "player\.src\(\[\{src\: \`"(?<sibnetUriPath>.*\.mp4)\`"" > $null
$sibnetVideoUriPath = $Matches.sibnetUriPath

. "$PSScriptRoot/helpers/open_vlc_player.ps1" "https://video.sibnet.ru$sibnetVideoUriPath" 'https://video.sibnet.ru/'