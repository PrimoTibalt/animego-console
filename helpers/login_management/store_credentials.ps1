param(
  [Parameter(Mandatory = $true)]
  [string]$usernameOrEmail,
  [Parameter(Mandatory = $true)]
  [string]$userPassword,
  [Parameter()]
  [string]$pathToSaveCredentials
)

if ($null -eq $pathToSaveCredentials) {
  $pathToSaveCredentials = "$PSScriptRoot/../../temp/creds.txt"
}

New-Item -Path $pathToSaveCredentials -Value "$usernameOrEmail;$userPassword" -Force > $null