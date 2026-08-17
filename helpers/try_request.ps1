param(
	[Parameter(Mandatory, Position = 0)]
	[string]$queryString,
	[Parameter(Position = 1)]
	[string]$referer,
	[Parameter(Position = 2)]
	[System.Threading.CancellationToken]$requestCancellationToken
)

$animegoLinks = @( 'animego.me', 'animego.club', 'animego.org', 'animego.one', 'animego.la' )

for ($sessionAttempt = 0; $sessionAttempt -lt 2; $sessionAttempt++) {
	$sessionCookies = . "$PSScriptRoot/login_management/get_session_cookies.ps1" ($sessionAttempt -gt 0)

	$tryRequestHeaders = @{
		'x-requested-with' = 'XMLHttpRequest'
		'Referer'        = $referer
		'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0'
		'Accept'         = 'application/json, text/javascript, */*; q=0.01'
		'Cache-Control'  = 'no-cache'
		'Pragma'         = 'no-cache'
	}

	if (-not [String]::IsNullOrEmpty($sessionCookies)) {
		$tryRequestHeaders['Cookie'] = $sessionCookies
	}

	foreach ($postfixVariant in $animegoLinks) {
		if ($null -ne $requestCancellationToken -and $requestCancellationToken.IsCancellationRequested) {
			return $null
		}

		if ([String]::IsNullOrEmpty($referer)) {
			$tryRequestHeaders['Referer'] = "https://$postfixVariant/"
		}

		$animegoPostfixVariantLink = [Uri]::new("https://$postfixVariant/$queryString")
		try {
			$response = Invoke-RestMethod -Uri $animegoPostfixVariantLink -Method 'Get' -Headers $tryRequestHeaders -TimeoutSec 15
			if ($response.status -ne 'success') {
				continue
			}

			if ($null -ne $response.data -and $null -ne $response.data.content) {
				return $response.data.content
			}

			return $response.content
		}
		catch {
			Set-Content "$PSScriptRoot/../temp/try_request_log.txt" "$animegoPostfixVariantLink`n$($_.Exception.Message)" -ErrorAction SilentlyContinue
			continue
		}
	}
}

return $null
