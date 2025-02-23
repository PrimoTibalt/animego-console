param(
	[Parameter(Mandatory, Position = 1)]
	[Int32]$number,
	[Parameter(Position = 2)]
	[Int32]$translation = 30,
	[Parameter(Mandatory, Position = 0)]
	[String]$link
)

Add-Type -AssemblyName 'System.Net'
$agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 Edg/133.0.0.0" 
$referrer = $link

$link -match "a(?<number>\d\d\d\d)" > $null
$playerLink = 'https://animego.me/anime/' + $Matches.number + `
							'/player?_allow=true'
$html = curl -X GET -s -H 'x-requested-with: XMLHttpRequest' -e $referrer -A $agent $playerLink

$json = ConvertFrom-Json -InputObject $html
$json.content -match "//aniboom`.one/embed/(?<hash>[^?]*)?" > $null

$animeUrl = 'https://aniboom.one/embed/' + $Matches.hash + `
						"?episode=$number&translation=$translation"
$referrer = 'https://animego.me/'
$html = curl -X GET -s -e $referrer -A $agent $animeUrl

$html = [System.Net.WebUtility]::HtmlDecode($html)
$html -match "data-parameters=`"{(?<parameters>[^ ]*)}`"" > $null
$result = '{' + $Matches.parameters + '}'
$json = ConvertFrom-Json -InputObject $result
switch -regex ($json.hls)
{
	'(?<link>https:[^ ]*m3u8)' {
		$m3u8 = $Matches.link.Replace('\/', '/')
		& .\open_vlc_player.ps1 -blob $m3u8
	}
	'(?<link>https:[^ ]*mpd)' {
		$mpv = $Matches.link.Replace('\/', '/')
		& .\open_vlc_player.ps1 -blob $mpv
	}
}