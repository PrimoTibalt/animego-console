param(
	[Parameter(Position = 0, Mandatory)]
	[SelectParameters]$multipageSelectParams
)

$currentLineOfMultipage = $Host.UI.RawUI.CursorPosition.Y + 1
$maxLineOfMultipage = $Host.UI.RawUI.BufferSize.Height

$estimatedSinglePageSize = $multipageSelectParams.dictForSelect.Count
if ($multipageSelectParams.withFallback) {
	$estimatedSinglePageSize = $estimatedSinglePageSize + 1
}

$multipageInitiated = $false
if ($currentLineOfMultipage + $estimatedSinglePageSize -gt $maxLineOfMultipage) {
	$multipageInitiated = $true
}

$currentPageOfMultipageSelect = 1;
$leftHeightForSelect = $maxLineOfMultipage - $currentLineOfMultipage - 3
if ($multipageSelectParams.withFallback) {
	$leftHeightForSelect--
}

if (-not [string]::IsNullOrEmpty($multipageSelectParams.message)) {
	$leftHeightForSelect--
}

$totalCountOfPages = [System.Math]::Ceiling([double]$multipageSelectParams.dictForSelect.Count / $leftHeightForSelect)

if ($multipageInitiated -and $null -ne $multipageSelectParams.preselectedValue) {
	$multipagePreselectIndex = 0
	foreach ($pair in $multipageSelectParams.dictForSelect.GetEnumerator()) {
		if ($pair.Key -eq $multipageSelectParams.preselectedValue) {
			$currentPageOfMultipageSelect = [Math]::Floor($multipagePreselectIndex / $leftHeightForSelect) + 1
			break
		}
		$multipagePreselectIndex++;
	}
}

while ($true) {
	$multipageDict = [ordered] @{}
	if ($multipageInitiated) {
		Write-Host "($currentPageOfMultipageSelect/$totalCountOfPages)"
		$multipagePairIndex = 0
		foreach ($pair in $multipageSelectParams.dictForSelect.GetEnumerator()) {
			if ([Math]::Floor($multipagePairIndex / $leftHeightForSelect) -eq $currentPageOfMultipageSelect - 1) {
				$multipageDict[$pair.Key] = $pair.Value;
			}

			$multipagePairIndex++;
		}

		$multipageDict['<-Prev']='prev';
		$multipageDict['>-Next']='next';
	}
	else {
		$multipageDict = $multipageSelectParams.dictForSelect
	}

	$updatedSelectParams = New-Object SelectParameters
	$updatedSelectParams.dictForSelect = $multipageDict
	$updatedSelectParams.message = $multipageSelectParams.message
	$updatedSelectParams.withFallback = $multipageSelectParams.withFallback
	$updatedSelectParams.returnKey = $multipageSelectParams.returnKey
	$updatedSelectParams.preselectedValue = $multipageSelectParams.preselectedValue
	$updatedSelectParams.showMessageOnSelect = $multipageSelectParams.showMessageOnSelect

	$selectMultipageResult = . "$PSScriptRoot/base_select.ps1" $updatedSelectParams
	if ($multipageInitiated) {
		. "$PSScriptRoot/../clean_console.ps1" 2
		if ($selectMultipageResult -eq 'next' -or $selectMultipageResult -eq '>-Next') {
			if ($currentPageOfMultipageSelect -eq $totalCountOfPages) {
				$currentPageOfMultipageSelect = 1
			} else {
				$currentPageOfMultipageSelect = $currentPageOfMultipageSelect + 1
			}
		}
		elseif ($selectMultipageResult -eq 'prev' -or $selectMultipageResult -eq '<-Prev') {
			if ($currentPageOfMultipageSelect -eq 1) {
				$currentPageOfMultipageSelect = $totalCountOfPages
			} else {
				$currentPageOfMultipageSelect = $currentPageOfMultipageSelect - 1
			}
		}
		else {
			return $selectMultipageResult
		}
	}
	else {
		return $selectMultipageResult
	}
}