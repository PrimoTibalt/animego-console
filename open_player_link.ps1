param(
	[Parameter(Position = 0, Mandatory)]
	$originalLink,
	[Parameter(Position = 1)]
	$dataId
)

$originalLink -match "-(?<number>\d\d\d\d)" > $null
$headers = @{
	'x-requested-with' = 'XMLHttpRequest'
	'Referer'        = $originalLink
	'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 Edg/133.0.0.0'
	'Accept'         = 'application/json, text/javascript, */*; q=0.01'
}

if ($null -ne $dataId) {
	$headers['Cookie'] = "episode_video=$dataId;"
}

$links = @( 'animego.me', 'animego.club', 'animego.org' )
foreach ($postfixVariant in $links) {
	$playerLink = "https://$postfixVariant/anime/" + $Matches.number + '/player?_allow=true'
	try {
		$response = Invoke-RestMethod -Uri $playerLink -Method 'Get' -Headers $headers -TimeoutSec 2
		if ($response.status -eq 'success') {
			Set-Content -Path ./temp/example.html $response.content
			return $response.content
			break
		}
	}
	catch {
		Write-Host "$postfixVariant did not succeed"
		continue
	}
}

return $null
