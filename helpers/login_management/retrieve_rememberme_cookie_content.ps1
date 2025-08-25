param(
  [Parameter(Mandatory = $true)]
  [string]$pathToSaveCookieToken
)

if (-not (Test-Path $pathToSaveCookieToken)) {
  return $null
}

$rememberMeFileContents = Get-Content -Path $pathToSaveCookieToken
if ([string]::IsNullOrEmpty($rememberMeFileContents)) {
  return $null
}

$rememberMeFileContents = $rememberMeFileContents.Split(';')
if ($rememberMeFileContents.Count -lt 2) {
  return $null
}

if ([string]::IsNullOrEmpty($rememberMeFileContents[0]) -or [string]::IsNullOrEmpty($rememberMeFileContents[1])) {
  return $null
}

$expirationDate = [DateTime]::Parse($rememberMeFileContents[1])

return [PSCustomObject]@{
  RememberMeToken = $rememberMeFileContents[0]
  ExpirationDate = $expirationDate
}