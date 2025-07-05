param(
	[Parameter(Mandatory, Position = 0)]
	[string]$episodePlayerDataLink,
	[Parameter(Position = 1)]
	[bool]$wantToDownload
)

Add-Type -AssemblyName 'System.Net'
$watchEpisodeHeaders = @{
	'Referer'        = 'https://animego.one/'
	'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0'
	'Accept'         = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7'
}

$playerHtml = Invoke-RestMethod -Uri $episodePlayerDataLink -Method 'Get' -Headers $watchEpisodeHeaders -TimeoutSec 5

$playerHtml = [System.Net.WebUtility]::HtmlDecode($playerHtml)
$playerHtml -match 'data-parameters="{(?<parameters>[^ ]*)}"' > $null
$result = '{' + $Matches.parameters + '}'
$playerJson = ConvertFrom-Json -InputObject $result
switch -regex ($playerJson.hls)
{
	'(?<link>https:[^ ]*m3u8)' {
		$m3u8 = $Matches.link.Replace('\/', '/')
		. "$PSScriptRoot/helpers/open_vlc_player.ps1" -blob $m3u8 $null $wantToDownload
	}
	'(?<link>https:[^ ]*mpd)' {
		$mpv = $Matches.link.Replace('\/', '/')
		. "$PSScriptRoot/helpers/open_vlc_player.ps1" -blob $mpv $null $wantToDownload
	}
}