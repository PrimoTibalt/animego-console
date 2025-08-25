param (
  [Parameter()]
  [string]$pathToSaveCredentials
)

$pathToSaveCredentials =  "$PSScriptRoot/../../temp/creds.txt"
$credsFromFile = . "$PSScriptRoot/get_credentials.ps1" $pathToSaveCredentials
if ($credsFromFile.UsernameOrEmail -eq 'false' -and $credsFromFile.UserPassword -eq 'false') {
  return $null
}

if ($null -eq $credsFromFile) {
  Write-Host 'Animego hides 18+ series during search if you are not authorized'
  Write-Host 'Enter username or email'
  Write-Host '(leave empty if dont want to login, the decision will be remembered):'
  $usernameOrEmailFromConsole = [Console]::ReadLine().Trim()
  if ([string]::IsNullOrEmpty($usernameOrEmailFromConsole)) {
    . "$PSScriptRoot/../clean_console.ps1" 4
    Set-Content -Path $pathToSaveCredentials -Value "false;false" -Force > $null
    return $null
  }

  Write-Host 'Enter password:'
  $userPasswordFromConsole = [Console]::ReadLine().Trim()
  $credsFromFile = [PSCustomObject]@{
    UsernameOrEmail = $usernameOrEmailFromConsole
    UserPassword = $userPasswordFromConsole
  }

  . "$PSScriptRoot/../clean_console.ps1" 6
}

return $credsFromFile