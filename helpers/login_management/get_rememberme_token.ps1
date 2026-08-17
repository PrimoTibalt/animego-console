param(
  [Parameter(Mandatory = $true)]
  [string]$usernameOrEmail,
  [Parameter(Mandatory = $true)]
  [string]$userPassword,
  [Parameter()]
  [string]$pathToSaveCookieToken
)

if ([string]::IsNullOrEmpty($pathToSaveCookieToken)) {
  $pathToSaveCookieToken = "$PSScriptRoot/../../temp/rememberme.txt"
}

$rememberMeFileContents = . "$PSScriptRoot/retrieve_rememberme_cookie_content.ps1" $pathToSaveCookieToken
if ($null -ne $rememberMeFileContents) {
  if ($rememberMeFileContents.ExpirationDate -gt [DateTime]::UtcNow) {
    return $rememberMeFileContents
  }
}

$loginUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0'
$loginRequestHeaders = @{
	'Referer'        = 'https://animego.me'
	'User-Agent'     = $loginUserAgent
	'Accept'         = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
	'Cache-Control'  = 'no-cache'
	'Pragma'         = 'no-cache'
}
$loginRequestResponse = Invoke-WebRequest -Uri 'https://animego.me/login' -Headers $loginRequestHeaders -Method 'Get'

$loginSessionCookies = (@($loginRequestResponse.Headers['Set-Cookie']) | ForEach-Object { $_.Split(';')[0] }) -join '; '
if ([string]::IsNullOrEmpty($loginSessionCookies)) {
  return $null
}

$loginPageContent = $loginRequestResponse.Content

$csrfForCurrentSession = . "$PSScriptRoot/../html_parsers/retrieve_csrf.ps1" $loginPageContent
if ([string]::IsNullOrEmpty($csrfForCurrentSession)) {
  return $null
}

$loginContentInList = [System.Collections.Generic.List[System.Collections.Generic.KeyValuePair[[string],[string]]]]::new()
$loginContentInList.Add([System.Collections.Generic.KeyValuePair[[string],[string]]]::new('_csrf_token', $csrfForCurrentSession))
$loginContentInList.Add([System.Collections.Generic.KeyValuePair[[string],[string]]]::new('_username', $usernameOrEmail))
$loginContentInList.Add([System.Collections.Generic.KeyValuePair[[string],[string]]]::new('_password', $userPassword))
$loginContentInList.Add([System.Collections.Generic.KeyValuePair[[string],[string]]]::new('_remember_me', 'on'))
$loginContent = [System.Net.Http.FormUrlEncodedContent]::new($loginContentInList)

$headersForLoginCheck = @{
  'Referer'='https://animego.me/login'
  'Origin'='https://animego.me'
  'User-Agent'=$loginUserAgent
  'Cookie'=$loginSessionCookies
}

$loginClientHandler = [System.Net.Http.HttpClientHandler]::new()
$loginClientHandler.AllowAutoRedirect = $false

$loginClient = [System.Net.Http.HttpClient]::new($loginClientHandler)
$requestToCheckLogin = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Post, 'https://animego.me/login')
$requestToCheckLogin.Content = $loginContent
foreach ($pairOfLoginCheckHeaders in $headersForLoginCheck.GetEnumerator()) {
  $requestToCheckLogin.Headers.Add($pairOfLoginCheckHeaders.Key, $pairOfLoginCheckHeaders.Value)
}

$loginCheckResult = $loginClient.Send($requestToCheckLogin, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead)
if (-not $loginCheckResult.Headers.Contains('Set-Cookie')) {
  return $null
}

$rememberMeAndDate = $loginCheckResult.Headers.GetValues('Set-Cookie') | Where-Object { $_.StartsWith('REMEMBERME') } | Select-Object -First 1
if ([string]::IsNullOrEmpty($rememberMeAndDate)) {
  return $null
}

$rememberMeSegments = $rememberMeAndDate.Replace('REMEMBERME=', [string]::Empty).Split(';')
$rememberMeCookie = $rememberMeSegments[0].Trim()
if ([string]::IsNullOrEmpty($rememberMeCookie) -or $rememberMeCookie -eq 'deleted') {
  return $null
}

$rememberMeExpirySegment = $rememberMeSegments | Where-Object { $_.Trim().StartsWith('expires=') } | Select-Object -First 1
if ([string]::IsNullOrEmpty($rememberMeExpirySegment)) {
  return $null
}

$rememberMeExpiryDate = $rememberMeExpirySegment.Trim().Replace('expires=', [string]::Empty)

New-Item -Path $pathToSaveCookieToken -Value "$rememberMeCookie;$rememberMeExpiryDate" -Force > $null

return . "$PSScriptRoot/retrieve_rememberme_cookie_content.ps1" $pathToSaveCookieToken
