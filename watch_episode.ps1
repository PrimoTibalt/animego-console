param(
	[Parameter(Mandatory, Position = 0)]
	[string]$link
)

Add-Type -AssemblyName 'System.Net'
$headers = @{
	'Referer'        = 'https://animego.one/'
	'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0'
	'Accept'         = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7'
}

$html = Invoke-RestMethod -Uri $link -Method 'Get' -Headers $headers -TimeoutSec 5

$html = [System.Net.WebUtility]::HtmlDecode($html)
$html -match "data-parameters=`"{(?<parameters>[^ ]*)}`"" > $null
$result = '{' + $Matches.parameters + '}'
$json = ConvertFrom-Json -InputObject $result
switch -regex ($json.hls)
{
	'(?<link>https:[^ ]*m3u8)' {
		$m3u8 = $Matches.link.Replace('\/', '/')
		. "$PSScriptRoot/helpers/open_vlc_player.ps1" -blob $m3u8
	}
	'(?<link>https:[^ ]*mpd)' {
		$mpv = $Matches.link.Replace('\/', '/')
		. "$PSScriptRoot/helpers/open_vlc_player.ps1" -blob $mpv
	}
}