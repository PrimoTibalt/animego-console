Write-Host 'This script registers animego-cli as Enter-Anime function in your terminal'
Write-Host 'You need to reopen your terminal for change to take effect'
$functionName = 'Enter-Anime'
if (-not (Get-Command $functionName -errorAction SilentlyContinue)) {
	"
	function $functionName {
	    $PSScriptRoot\run.ps1
	}
	" >> $PROFILE
}