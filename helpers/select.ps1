param(
	[Parameter(Position = 0, Mandatory)]
	[System.Collections.Specialized.OrderedDictionary]$dict,
	[Parameter(Position = 1)]
	[string]$message
)

$inputs = @{
	'75' = -1;
	'38' = -1;
	'74' = 1;
	'40' = 1
}

$selected = 0
$options = [System.Management.Automation.Host.ReadKeyOptions]"NoEcho" + [System.Management.Automation.Host.ReadKeyOptions]"IncludeKeyDown"

Write-Host $message
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

	& ./helpers/clean_console.ps1 $dict.Keys.Count

	if ($pressedKey.VirtualKeyCode -eq '0') {
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
			$selected = $dict.Keys.Count-1
		}
 
		if ($dict.Keys.Count-1 -lt $selected) {
			$selected = 0
		}
	}
}

$index = 0
foreach ($pair in $dict.GetEnumerator()) {
	if ($index -eq $selected) {
		$key = $pair.Key
		Write-Host "You chose $key"
		return $dict.$key
	}

	$index++
}