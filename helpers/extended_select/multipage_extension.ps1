param(
	[Parameter(Position = 0, Mandatory)]
	[System.Collections.Specialized.OrderedDictionary]$dictForMultipage,
	[Parameter(Position = 1)]
	[string]$message,
	[Parameter(Position = 2)]
	[bool]$withFallback = $true,
	[Parameter(Position = 3)]
	[bool]$returnKey = $false,
	[Parameter(Position = 4)]
	$preselectedValue,
	[Parameter(Position = 5)]
	$showMessageOnSelect
)

$currentLineOfMultipage = $Host.UI.RawUI.CursorPosition.Y + 1
$maxLineOfMultipage = $Host.UI.RawUI.BufferSize.Height

$estimatedSinglePageSize = $dictForMultipage.Count
if ($withFallback) {
	$estimatedSinglePageSize = $estimatedSinglePageSize + 1
}

$multipageInitiated = $false
if ($currentLineOfMultipage + $estimatedSinglePageSize -gt $maxLineOfMultipage) {
	$multipageInitiated = $true
}

$currentPageOfMultipageSelect = 1;
$leftHeightForSelect = $maxLineOfMultipage - $currentLineOfMultipage - 3
if ($withFallback) {
	$leftHeightForSelect--
}

if (-not [string]::IsNullOrEmpty($message)) {
	$leftHeightForSelect--
}

$totalCountOfPages = [System.Math]::Ceiling([double]$dictForMultipage.Count / $leftHeightForSelect)

if ($multipageInitiated -and $null -ne $preselectedValue) {
	$multipagePreselectIndex = 0
	foreach ($pair in $dictForMultipage.GetEnumerator()) {
		if ($pair.Key -eq $preselectedValue) {
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
		foreach ($pair in $dictForMultipage.GetEnumerator()) {
			if ([Math]::Floor($multipagePairIndex / $leftHeightForSelect) -eq $currentPageOfMultipageSelect - 1) {
				$multipageDict[$pair.Key] = $pair.Value;
			}

			$multipagePairIndex++;
		}

		$multipageDict['<-Prev']='prev';
		$multipageDict['>-Next']='next';
	}
	else {
		$multipageDict = $dictForMultipage
	}

	$selectMultipageResult = . "$PSScriptRoot/base_select.ps1" $multipageDict $message $withFallback $returnKey $preselectedValue $showMessageOnSelect
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