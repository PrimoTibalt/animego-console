param(
	[Parameter(Mandatory, Position = 0)]
	[string]$queryString,
	[Parameter(Position = 1)]
	[string]$referer = 'https://animego.club/',
	[Parameter(Position = 2)]
	[string]$cookie
)

$links = @( 'animego.me', 'animego.club', 'animego.org' )
$headers = @{
	'x-requested-with' = 'XMLHttpRequest'
	'Referer'        = $referer
	'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 Edg/133.0.0.0'
	'Accept'         = 'application/json, text/javascript, */*; q=0.01'
}

if (-not [String]::IsNullOrEmpty($cookie)) {
	$headers['Cookie'] = $cookie
}

foreach ($postfixVariant in $links) {
	$link = "https://$postfixVariant/$queryString"
	try {
		$response = Invoke-RestMethod -Uri $link -Method 'Get' -Headers $headers -TimeoutSec 2
		if ($response.status -eq 'success') {
			return $response.content
			break
		}
	}
	catch {
		continue
	}
}

return $null