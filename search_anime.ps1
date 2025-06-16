$searchInputText = ''
$searchAnimeSelectParameters = New-Object SelectParameters
$searchAnimeSelectParameters.dictForSelect = [ordered]@{}
$searchAnimeSelectParameters.withFallback = $false
$searchAnimeSelectParameters.returnKey = $true
$searchAnimeSelectParameters.showMessageOnSelect = $false

while ($true) {
	if (-not [Console]::KeyAvailable) {
		[System.Threading.Thread]::Sleep(50)
		continue
	}

	if ($null -ne $cts) {
		$cts.Cancel()
	}

	$cts = [System.Threading.CancellationTokenSource]::new()

	$key = [Console]::ReadKey()

	if ($key.Key -eq [System.ConsoleKey]::Enter -and $searchAnimeSelectParameters.dictForSelect.Count -gt 0) {
		[Console]::SetCursorPosition(0, 1)
		$searchAnimeSelectParameters.dictForSelect['...'] = $null
		$animeNameFromSearch = . "$PSScriptRoot/helpers/select.ps1" $searchAnimeSelectParameters
		if ($animeNameFromSearch -eq '...') {
			$searchAnimeSelectParameters.dictForSelect.Remove('...')
			[Console]::SetCursorPosition(0, 1);
			foreach ($pair in $searchAnimeSelectParameters.dictForSelect.GetEnumerator()) {
				Write-Host $pair.Key
			}

			[Console]::SetCursorPosition($searchInputText.Length, 0)
			continue
		}

		$animeLinkFull = . "$PSScriptRoot/helpers/watched_management/synchronize_to_state.ps1" $animeNameFromSearch
		if ([string]::IsNullOrEmpty($animeLinkFull)) {
			$animeLink = $searchAnimeSelectParameters.dictForSelect.$animeNameFromSearch
			$animeLinkFull = "https://animego.one$animeLink"
			. "$PSScriptRoot/helpers/state_management/create_state.ps1" $animeNameFromSearch $animeLinkFull
		}

		. "$PSScriptRoot/select_episode.ps1" $animeLinkFull
		Clear-Host
		[Console]::Write($searchInputText)
	}

	if ($key.KeyChar -eq '`') {
		Clear-Host
		break
	}

	if ($key.Key -eq [System.ConsoleKey]::Backspace) {
		if (-not [string]::IsNullOrEmpty($searchInputText)) {
			[Console]::Write("{0,-1}" -f "")
			$searchInputText = $searchInputText.Substring(0, $searchInputText.Length - 1)
			[Console]::SetCursorPosition($searchInputText.Length, 0)
		}
	} else {
		$searchInputText = $searchInputText + $key.KeyChar
	}


	if ($searchInputText.Length -ge 4) {
		$searchAnimeSelectParameters.dictForSelect = . "$PSScriptRoot/helpers/request_anime_by_name.ps1" $searchInputText $searchAnimeSelectParameters.dictForSelect $cts.Token
	}
}