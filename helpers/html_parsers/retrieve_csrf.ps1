param(
  [Parameter(Mandatory = $true)]
  [string]$loginPageHtml
)

New-Item -Path "$PSScriptRoot/../../temp/login.html" -Value $loginPageHtml -Force *> $null

if ([string]::IsNullOrEmpty($loginPageHtml)) {
  return $null
}

$loginHtmlDocument = [HtmlAgilityPack.HtmlDocument]::new()
$loginHtmlDocument.LoadHtml($loginPageHtml)

$csrfTokenFromDocument = $loginHtmlDocument.DocumentNode.SelectSingleNode("//input[@name='_csrf_token']")
return $csrfTokenFromDocument.GetAttributeValue('value', [string]::Empty)