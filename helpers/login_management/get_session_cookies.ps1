param(
	[Parameter(Position = 0)]
	[bool]$forceRefresh
)

$sessionCookiesPath = "$PSScriptRoot/../../temp/session_cookies.txt"
$sessionCookiesLifetime = [TimeSpan]::FromMinutes(30)

$rememberMeTokenData = . "$PSScriptRoot/retrieve_rememberme_cookie_content.ps1" "$PSScriptRoot/../../temp/rememberme.txt"
$rememberMeCookiePart = $null
if ($null -ne $rememberMeTokenData -and $rememberMeTokenData.ExpirationDate -gt [DateTime]::UtcNow) {
	$rememberMeCookiePart = "REMEMBERME=$($rememberMeTokenData.RememberMeToken)"
}

if (-not $forceRefresh) {
	$cachedSessionCookies = $global:animegoSessionCookies
	if ([string]::IsNullOrEmpty($cachedSessionCookies) -and (Test-Path $sessionCookiesPath)) {
		$sessionCookiesFile = Get-Item $sessionCookiesPath
		if (([DateTime]::UtcNow - $sessionCookiesFile.LastWriteTimeUtc) -lt $sessionCookiesLifetime) {
			$cachedSessionCookies = (Get-Content $sessionCookiesPath -Raw).Trim()
		}
	}

	if (-not [string]::IsNullOrEmpty($cachedSessionCookies)) {
		$cachedMatchesLogin = if ($null -eq $rememberMeCookiePart) {
			-not $cachedSessionCookies.Contains('REMEMBERME=')
		} else {
			$cachedSessionCookies.Contains($rememberMeCookiePart)
		}

		if ($cachedMatchesLogin) {
			$global:animegoSessionCookies = $cachedSessionCookies
			return $cachedSessionCookies
		}
	}
}

$sessionUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0'
try {
	$warmUpResponse = Invoke-WebRequest -Uri 'https://animego.me/' -Headers @{ 'User-Agent' = $sessionUserAgent } -Method 'Get' -TimeoutSec 15
} catch {
	return $null
}

$sessionCookieParts = @(@($warmUpResponse.Headers['Set-Cookie']) | ForEach-Object { $_.Split(';')[0].Trim() } | Where-Object { -not [string]::IsNullOrEmpty($_) })
if ($sessionCookieParts.Count -eq 0) {
	return $null
}

if ($null -ne $rememberMeCookiePart) {
	$sessionCookieParts += $rememberMeCookiePart
}

$global:animegoSessionCookies = $sessionCookieParts -join '; '
New-Item -Path $sessionCookiesPath -Value $global:animegoSessionCookies -Force > $null

return $global:animegoSessionCookies
