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

$loginRequestHeaders = @{
	'Referer'        = 'https://animego.me'
	'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0'
	'Accept'         = 'application/json, text/javascript, */*; q=0.01'
	'Cache-Control'  = 'no-cache'
	'Pragma'         = 'no-cache'
}
$loginRequestResponse = Invoke-WebRequest -Uri "https://animego.me/login" -Headers $loginRequestHeaders -Method 'Get'
$phpsessId = $loginRequestResponse.Headers['Set-Cookie'].Split(';') | Where-Object { $_.Contains('PHPSESSID') }
$phpsessId = $phpsessId.Split('=')[1]
$loginPageContent = $loginRequestResponse.content

$csrfForCurrentSession = . "$PSScriptRoot/../html_parsers/retrieve_csrf.ps1" $loginPageContent
$loginContentInList = [System.Collections.Generic.List[System.Collections.Generic.KeyValuePair[[string],[string]]]]::new()
$loginContentInList.Add([System.Collections.Generic.KeyValuePair[[string],[string]]]::new('_csrf_token', $csrfForCurrentSession))
$loginContentInList.Add([System.Collections.Generic.KeyValuePair[[string],[string]]]::new('_username', $usernameOrEmail))
$loginContentInList.Add([System.Collections.Generic.KeyValuePair[[string],[string]]]::new('_password', $userPassword))
$loginContentInList.Add([System.Collections.Generic.KeyValuePair[[string],[string]]]::new('_remember_me', 'on'))
$loginContentInList.Add([System.Collections.Generic.KeyValuePair[[string],[string]]]::new('_submit', 'Войти'))
$loginContent = [System.Net.Http.FormUrlEncodedContent]::new($loginContentInList)

$headersForLoginCheck = @{
  'Referer'='https://animego.me/login'
  'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36' 
  'Cookie'="PHPSESSID=$phpsessId; path=/; HttpOnly"
}

$loginClientHandler = [System.Net.Http.HttpClientHandler]::new()
$loginClientHandler.AllowAutoRedirect = $false

$loginClient = [System.Net.Http.HttpClient]::new($loginClientHandler)
$requestToCheckLogin = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Post, 'https://animego.me/login_check')
$requestToCheckLogin.Content = $loginContent
foreach ($pairOfLoginCheckHeaders in $headersForLoginCheck.GetEnumerator()) {
  $requestToCheckLogin.Headers.Add($pairOfLoginCheckHeaders.Key, $pairOfLoginCheckHeaders.Value)
}

$loginCheckResult = $loginClient.Send($requestToCheckLogin, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead)
$rememberMeAndDate = $loginCheckResult.Headers.GetValues('Set-Cookie') | Where-Object { $_.StartsWith('REMEMBERME') }
if ([string]::IsNullOrEmpty($rememberMeAndDate)) {
  return $null
}

$rememberMeAndDate = $rememberMeAndDate.Replace('REMEMBERME=', [string]::Empty).Split(';')
$rememberMeCookie = $rememberMeAndDate[0]
$rememberMeExpiryDate = $rememberMeAndDate[1].Replace(' expires=', [string]::Empty)

New-Item -Path $pathToSaveCookieToken -Value "$rememberMeCookie;$rememberMeExpiryDate" -Force > $null

return . "$PSScriptRoot/retrieve_rememberme_cookie_content.ps1" $pathToSaveCookieToken