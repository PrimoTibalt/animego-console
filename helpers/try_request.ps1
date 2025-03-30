param(
	[Parameter(Mandatory, Position = 0)]
	[string]$queryString,
	[Parameter(Position = 1)]
	[string]$referer,
	[Parameter(Position = 2)]
	[string]$cookie
)

$animegoLinks = @( 'animego.me', 'animego.club', 'animego.org', 'animego.one' )
$tryRequestHeaders = @{
	'x-requested-with' = 'XMLHttpRequest'
	'Referer'        = $referer
	'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0'
	'Accept'         = 'application/json, text/javascript, */*; q=0.01'
	'Cache-Control'  = 'no-cache'
	'Pragma'         = 'no-cache'
}

if (-not [String]::IsNullOrEmpty($cookie)) {
	$tryRequestHeaders['Cookie'] = $cookie
}

foreach ($postfixVariant in $animegoLinks) {
	if ([String]::IsNullOrEmpty($referer)) {
		$tryRequestHeaders['Referer'] = "https://$postfixVariant/"
	}

	$animegoPostfixVariantLink = [Uri]::new("https://$postfixVariant/$queryString")
	try {
		$response = Invoke-RestMethod -Uri $animegoPostfixVariantLink -Method 'Get' -Headers $tryRequestHeaders -TimeoutSec 2
		Set-Content "$PSScriptRoot/../temp/try_request_log.html" $response
		if ($response.status -eq 'success') {
			return $response.content
			break
		}
	}
	catch {
		Set-Content "$PSScriptRoot/../temp/try_request_log.html" $response
		continue
	}
}

return $null