param(
  [Parameter()]
  [string]$pathToSaveCredentials
)

if ([string]::IsNullOrEmpty($pathToSaveCredentials)) {
  $pathToSaveCredentials = "$PSScriptRoot/../../temp/creds.txt"
}

if (Test-Path -Path $pathToSaveCredentials) {
  $credentialsOfUser = Get-Content -Path $pathToSaveCredentials
  $credentialsOfUser = $credentialsOfUser.Split(';')
  return [PSCustomObject]@{
    UsernameOrEmail = $credentialsOfUser[0]
    UserPassword = $credentialsOfUser[1]
  }
}

return $null