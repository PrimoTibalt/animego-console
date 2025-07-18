param(
	[Parameter(Position = 0, Mandatory)]
	[SelectParameters]$selectParameters
)

$selected = 0
$fallbackSign = '__'
if ($selectParameters.withFallback -and (-1 -eq $selectParameters.dictForSelect.Keys.IndexOf($fallbackSign))) {
	$selectParameters.dictForSelect = [ordered]@{ $fallbackSign = $null } + $selectParameters.dictForSelect
}

$count = $selectParameters.dictForSelect.Keys.Count

if (-not [string]::IsNullOrWhiteSpace($selectParameters.preselectedValue)) {
	$selected = $selectParameters.dictForSelect.Keys.IndexOf($selectParameters.preselectedValue)
	if ($selected -lt 0) {
		$selected = 0
	}
}

$inputs = @{
	'75' = { $script:selected = $selected - 1 };
	'38' = { $script:selected = $selected - 1 };
	'74' = { $script:selected = $selected + 1 };
	'40' = { $script:selected = $selected + 1 };
	'13' = { . "$PSScriptRoot/../clean_console.ps1" $script:count; break; };
	'70' = {
		if ($null -ne $selectParameters.actionOnF) {
			$actionOnFIndex = 0
			foreach ($pair in $selectParameters.dictForSelect.GetEnumerator()) {
				if ($actionOnFIndex -eq $selected) {
					$selectParameters.actionOnF.Invoke($pair.Key, $pair.Value)
				}

				$actionOnFIndex++
			}
		}
	};
	'82' = {
		if ($null -ne $selectParameters.actionOnR) {
			$actionOnRIndex = 0
			foreach ($pair in $selectParameters.dictForSelect.GetEnumerator()) {
				if ($actionOnRIndex -eq $selected) {
					$selectParameters.actionOnR.Invoke($pair.Key)
				}

				$actionOnRIndex++
			}
		}
	};
	'72' = [Func[[string]]]{
		if ($null -ne $selectParameters.dictForSelect['<-Prev']) {
			return $selectParameters.dictForSelect['<-Prev']
		}
	};
	'76' = [Func[[string]]]{
		if ($null -ne $selectParameters.dictForSelect['>-Next']) {
			return $selectParameters.dictForSelect['>-Next']
		}
	}
}

if (-not [string]::IsNullOrEmpty($selectParameters.message)) {
	Write-Host $selectParameters.message
}

$index1 = 0
foreach ($pair in $selectParameters.dictForSelect.GetEnumerator()) {
	$pairKey = $pair.Key
	if ($null -ne $selectParameters.actionOnEachKey) {
		$pairKey = $selectParameters.actionOnEachKey.Invoke($pairKey)
	}

	if ($index1 -eq $selected) {
		Write-Host -ForegroundColor Green $pairKey
	} else {
		Write-Host $pairKey
	}

	$index1++
}

$printLine = [Action[[string],[bool]]]{ 
	param(
		$textToPrint,
		$printGreen
	)
	if ($null -ne $script:selectParameters.actionOnEachKey) {
		$textToPrint = $script:selectParameters.actionOnEachKey.Invoke($textToPrint)
	}
	$currentUiPosition = $Host.UI.RawUI.CursorPosition.Y
	[Console]::SetCursorPosition(0, $currentUiPosition - $script:count + $script:index2)

	if ($printGreen) {
		Write-Host -ForegroundColor Green $textToPrint
	} else {
		Write-Host $textToPrint
	}

	[Console]::SetCursorPosition(0, $currentUiPosition)
}

$previouslySelected = 0
while ($true) {
	$pressedKey = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	$keyPressed = $pressedKey.VirtualKeyCode.ToString()

	if ($inputs.ContainsKey($keyPressed)) {
		$previouslySelected = $selected
		$invokeResult = $inputs[$keyPressed].Invoke()
		if ($null -ne $invokeResult -and $invokeResult.GetType() -eq [string]) {
			. "$PSScriptRoot/../clean_console.ps1" $count
			return $invokeResult
		}

		if ($selected -lt 0) {
			$selected = $count - 1
		} elseif (($count - 1) -lt $selected) {
			$selected = 0
		}
	}

	$index2 = 0
	foreach ($pair in $selectParameters.dictForSelect.GetEnumerator()) {
		$pairKey = $pair.Key
		if ($index2 -eq $selected) {
			$printLine.Invoke($pairKey, $true)
		} elseif ($index2 -eq $previouslySelected) {
			$printLine.Invoke($pairKey, $false)
		}

		$index2++
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