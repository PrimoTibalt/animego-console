param(
	[Parameter(Position = 0, Mandatory)]
	[System.Collections.Specialized.OrderedDictionary]$dict,
	[Parameter(Position = 1)]
	[string]$message,
	[Parameter(Position = 2)]
	[bool]$withFallback = $true,
	[Parameter(Position = 3)]
	[bool]$returnKey = $false,
	[Parameter(Position = 4)]
	$preselectedValue
)

$fallbackSign = '__'
$inputs = @{
	'75' = -1;
	'38' = -1;
	'74' = 1;
	'40' = 1
}
if ($withFallback) {
	$dict = [ordered]@{ $fallbackSign = $null } + $dict
}

$selected = 0
if (-not [string]::IsNullOrWhiteSpace($preselectedValue)) {
	$selected = $dict.Keys.IndexOf($preselectedValue)
	if ($selected -lt 0) {
		$selected = 0
	}
}

$options = "NoEcho,IncludeKeyDown"
$count = $dict.Keys.Count

if (-not [string]::IsNullOrEmpty($message)) {
	Write-Host $message
}

while ($true) {
	$index = 0
	foreach ($pair in $dict.GetEnumerator()) {
		if ($index -eq $selected) {
			Write-Host -ForegroundColor Green $pair.Key
		} else {
			Write-Host $pair.Key
		}

		$index++
	}

	$pressedKey = $Host.UI.RawUI.ReadKey($options)
	. "$PSScriptRoot/clean_console.ps1" $count

	if (-not $Host.Name -like "*Visual Studio Code*" -and $pressedKey.VirtualKeyCode -eq '0') {
		return
	}

	if ($pressedKey.VirtualKeyCode -eq '13') {
		break
	}

	$keyPressed = $pressedKey.VirtualKeyCode.ToString()
	if ($inputs.ContainsKey($keyPressed)) {
		$val = $inputs[$keyPressed]
		$selected = $selected + $val
		if ($selected -lt 0) {
			$selected = $count - 1
		}
 
		if ($count -1 -lt $selected) {
			$selected = 0
		}
	}
}

if (-not [string]::IsNullOrEmpty($message)) {
	. "$PSScriptRoot/clean_console.ps1" 1
}

$index = 0
foreach ($pair in $dict.GetEnumerator()) {
	if ($index -eq $selected) {
		$key = $pair.Key
		if ($key -ne $fallbackSign) {
			Write-Host "You chose $key"
		}

		if ($returnKey) {
			return $key
		}

		return $dict.$key
	}

	$index++
}