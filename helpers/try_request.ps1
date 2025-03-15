param(
	[Parameter(Mandatory, Position = 0)]
	[string]$queryString,
	[Parameter(Position = 1)]
	[string]$referer,
	[Parameter(Position = 2)]
	[string]$cookie
)

$links = @( 'animego.me', 'animego.club', 'animego.org', 'animego.one' )
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
	if ([String]::IsNullOrEmpty($referer)) {
		$headers['Referer'] = "https://$postfixVariant/"
	}

	$link = "https://$postfixVariant/$queryString"
	try {
		$response = Invoke-RestMethod -Uri $link -Method 'Get' -Headers $headers -TimeoutSec 2
		if ($response.status -eq 'success') {
			Set-Content ./temp/example.html $response.content
			return $response.content
			break
		}
	}
	catch {
		Set-Content ./temp/log.html $response.content
		continue
	}
}

return $null