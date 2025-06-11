$searchInputText = ''
$foundAnimeMapToHrefMap = [ordered]@{}

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

	if ($key.Key -eq [System.ConsoleKey]::Enter -and $foundAnimeMapToHrefMap.Count -gt 0) {
		[Console]::SetCursorPosition(0, 1)
		$foundAnimeMapToHrefMap['...'] = $null
		$name = . "$PSScriptRoot/helpers/select.ps1" $foundAnimeMapToHrefMap $null $false $true $null $false
		if ($name -eq '...') {
			$foundAnimeMapToHrefMap.Remove('...')
			[Console]::SetCursorPosition(0, 1);
			foreach ($pair in $foundAnimeMapToHrefMap.GetEnumerator()) {
				Write-Host $pair.Key
			}

			[Console]::SetCursorPosition($searchInputText.Length, 0)
			continue
		}
		$animeLinkFull = . "$PSScriptRoot/helpers/watched_management/synchronize_to_state.ps1" $name
		if ([string]::IsNullOrEmpty($animeLinkFull)) {
			$animeLink = $foundAnimeMapToHrefMap.$name
			$animeLinkFull = "https://animego.one$animeLink"
			. "$PSScriptRoot/helpers/state_management/create_state.ps1" $name $animeLinkFull
		}

		. "$PSScriptRoot/select_episode.ps1" $animeLinkFull
		Clear-Host
		continue
	}

	if ($key.KeyChar -eq '`') {
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
		$foundAnimeMapToHrefMap = . "$PSScriptRoot/helpers/request_anime_by_name.ps1" $searchInputText $foundAnimeMapToHrefMap $cts.Token
	}
}