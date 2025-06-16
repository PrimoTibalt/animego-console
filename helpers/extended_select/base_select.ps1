param(
	[Parameter(Position = 0, Mandatory)]
	[SelectParameters]$selectParameters
)

$fallbackSign = '__'
$inputs = @{
	'75' = -1;
	'38' = -1;
	'74' = 1;
	'40' = 1
}
if ($selectParameters.withFallback -and (-1 -eq $selectParameters.dictForSelect.Keys.IndexOf($fallbackSign))) {
	$selectParameters.dictForSelect = [ordered]@{ $fallbackSign = $null } + $selectParameters.dictForSelect
}

$selected = 0
if (-not [string]::IsNullOrWhiteSpace($selectParameters.preselectedValue)) {
	$selected = $selectParameters.dictForSelect.Keys.IndexOf($selectParameters.preselectedValue)
	if ($selected -lt 0) {
		$selected = 0
	}
}

$count = $selectParameters.dictForSelect.Keys.Count

if (-not [string]::IsNullOrEmpty($selectParameters.message)) {
	Write-Host $selectParameters.message
}

while ($true) {
	$index = 0
	foreach ($pair in $selectParameters.dictForSelect.GetEnumerator()) {
		if ($index -eq $selected) {
			Write-Host -ForegroundColor Green $pair.Key
		} else {
			Write-Host $pair.Key
		}

		$index++
	}

	$pressedKey = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	. "$PSScriptRoot/../clean_console.ps1" $count

	if (-not $Host.Name -like "*Visual Studio Code*" -and $pressedKey.VirtualKeyCode -eq '0') {
		return
	}

	if ($pressedKey.VirtualKeyCode -eq '13') {
		break
	}
	
	if ($pressedKey.VirtualKeyCode -eq '72' -and $null -ne $selectParameters.dictForSelect['<-Prev']) {
		return $selectParameters.dictForSelect['<-Prev']
	}

	if ($pressedKey.VirtualKeyCode -eq '76' -and $null -ne $selectParameters.dictForSelect['>-Next']) {
		return $selectParameters.dictForSelect['>-Next']
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

if (-not [string]::IsNullOrEmpty($selectParameters.message)) {
	. "$PSScriptRoot/../clean_console.ps1" 1
}

$index = 0
foreach ($pair in $selectParameters.dictForSelect.GetEnumerator()) {
	if ($index -eq $selected) {
		$key = $pair.Key
		if ($selectParameters.showMessageOnSelect -and ($key -ne $fallbackSign -and $key -ne '<-Prev' -and $key -ne '>-Next')) {
			Write-Host "You chose $key"
		}

		if ($selectParameters.returnKey) {
			return $key
		}

		return $selectParameters.dictForSelect.$key
	}

	$index++
}