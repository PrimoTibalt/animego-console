param(
	[Parameter(Position = 0, Mandatory)]
	[System.Collections.Specialized.OrderedDictionary]$dict
)

$inputs = @{
	'75' = -1;
	'38' = -1;
	'74' = 1;
	'40' = 1
}
$selected = $dict.Keys[0]
$options = [System.Management.Automation.Host.ReadKeyOptions]"NoEcho" + [System.Management.Automation.Host.ReadKeyOptions]"IncludeKeyDown"
while ($true) {
	Write-Output 'Choose episode:'
	foreach ($pair in $dict.GetEnumerator()) {
		if ($pair.Key -eq $selected) {
			Write-Host -BackgroundColor Green $pair.Key
		} else {
			Write-Output $pair.Key
		}
	}

	$pressedKey = $Host.UI.RawUI.ReadKey($options)
	if ($pressedKey.VirtualKeyCode -eq '0') {
		return;
	}

	if ($pressedKey.VirtualKeyCode -eq '13') {
		break;
	}

	$keyPressed = $pressedKey.VirtualKeyCode.ToString()
	if ($inputs.ContainsKey($keyPressed)) {
		$val = $inputs[$keyPressed]
		$selected = $selected + $val
		if ($selected -lt $dict.Keys[0]) {
			$selected = $dict.Keys[0]
		}
 
		if ($dict.Keys[$dict.Keys.Count-1] -lt $selected) {
			$selected = $dict.Keys[$dict.Keys.Count-1]
		}

		Clear-Host
	}
}

return $dict.$selected