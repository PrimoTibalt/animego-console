param(
	[Parameter(Mandatory, Position = 1)]
	[Int32]$number,
	[Parameter(Position = 2)]
	[Int32]$translation = 30,
	[Parameter(Mandatory, Position = 0)]
	[String]$link
)

Add-Type -AssemblyName 'System.Net'
$link -match "-(?<number>\d\d\d\d)" > $null
$headers = @{
	'x-requested-with' = 'XMLHttpRequest'
	'Referer'        = $link
	'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 Edg/133.0.0.0'
	'Accept'         = 'application/json, text/javascript, */*; q=0.01'
}

$links = @( 'animego.me', 'animego.club', 'animego.org' )
foreach ($postfixVariant in $links) {
	$playerLink = "https://$postfixVariant/anime/" + $Matches.number + '/player?_allow=true'
	try {
		$response = Invoke-RestMethod -Uri $playerLink -Method 'Get' -Headers $headers -TimeoutSec 1
		if ($response.status -eq 'success') {
			Write-Output "Successfuly retrieved from $postfixVariant"
			$html = $response.content
			break;
		}
	}
	catch {
		Write-Output "$postfixVariant did not succeed"
		continue;
	}
}

if ($null -eq $html) {
	Write-Output 'Content is empty'
	return;
}

$html -match "//aniboom`.one/embed/(?<hash>[^?]*)?" > $null

$animeUrl = 'https://aniboom.one/embed/' + $Matches.hash + `
						"?episode=$number&translation=$translation"
$headers.Referer = 'https://animego.me/'
$html = Invoke-RestMethod -Uri $animeUrl -Method 'Get' -Headers $headers -TimeoutSec 1

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