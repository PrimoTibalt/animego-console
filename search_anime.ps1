$searchInputText = ''
$searchAnimeSelectParameters = New-Object SelectParameters
$searchAnimeSelectParameters.dictForSelect = [ordered]@{}
$searchAnimeSelectParameters.withFallback = $false
$searchAnimeSelectParameters.returnKey = $true
$searchAnimeSelectParameters.showMessageOnSelect = $false
$searchAnimeSelectParameters.actionOnF = [Action[[string],[string]]]{
	param([string]$addToFavoriteAnimeName, [string]$addToFavoriteAnimeHref)

	$addToFavoriteAnimeHref = "https://animego.one$addToFavoriteAnimeHref"
	. "$PSScriptRoot/helpers/favorite_management/add_new_favorite.ps1" $addToFavoriteAnimeName $addToFavoriteAnimeHref
}
$searchAnimeSelectParameters.actionOnEachKey = [Func[[string],[string]]]{
	param([string]$dictionaryKey)

	$favoriteAnimes = . "$PSScriptRoot/helpers/favorite_management/get_favorites.ps1"

	if ($null -ne $favoriteAnimes[$dictionaryKey]) {
		return '★ ' + $dictionaryKey
	}
	else {
		return $dictionaryKey
	}
}
$searchAnimeSelectParameters.actionOnR = [Action[[string]]]{
	param([string]$removeFromFavoriteAnimeName)

	. "$PSScriptRoot/helpers/favorite_management/remove_favorite.ps1" $removeFromFavoriteAnimeName
}

$pathToCredentialsFile = "$PSScriptRoot/temp/creds.txt"
$userCreds = . "$PSScriptRoot/helpers/login_management/login.ps1" $pathToCredentialsFile
$pathToRememberMeToken = "$PSScriptRoot/temp/rememberme.txt"
if ($null -ne $userCreds) {
	$rememberMeTokenData = . "$PSScriptRoot/helpers/login_management/get_rememberme_token.ps1" $userCreds.UsernameOrEmail $userCreds.UserPassword $pathToRememberMeToken
	if ($null -ne $rememberMeTokenData) {
		$rememberMeToken = $rememberMeTokenData.RememberMeToken
	}
}

$pathToSearchOutputLog = "$PSScriptRoot/temp/search_log.txt" 
New-Item -Path $pathToSearchOutputLog -Value '' -Force *> $null
$searchLogFileStream = New-Object System.IO.FileStream($pathToSearchOutputLog, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite) 
$searchLogStringReader = New-Object System.IO.StreamReader($searchLogFileStream)
$linesOfAnimeCounter = 0
$shouldCleanUp = $false
$dictForSearchSelectNew = [ordered]@{}
while ($true) { # Reading keys from console in a loop
	if (-not [Console]::KeyAvailable) {
		try {
			$isNewProcess = $searchProcessId -ne $requestAnimeProcess.Id
			if ($isNewProcess) {
				$searchLogStringReader.BaseStream.Seek(0, [System.IO.SeekOrigin]::Begin) > $null
				$shouldCleanUp = $true
				$searchProcessId = $requestAnimeProcess.Id
			}

			$lineFromSearchResult = $searchLogStringReader.ReadLine()

			if (-not [string]::IsNullOrWhiteSpace($lineFromSearchResult)) {
				if ($shouldCleanUp) {
					if ($dictForSearchSelectNew.Count -ne 0) {
						[Console]::SetCursorPosition(0, $dictForSearchSelectNew.Count + 1)
						& "$PSScriptRoot/helpers/clean_console.ps1" $dictForSearchSelectNew.Count
						$linesOfAnimeCounter = 0
						[Console]::SetCursorPosition($searchInputText.Length, 0)
						$dictForSearchSelectNew = [ordered]@{}
					}

					$shouldCleanUp = $false
				}

				$linesOfAnimeCounter++
				if ($linesOfAnimeCounter % 2 -eq 1) {
					[Console]::SetCursorPosition(0, $dictForSearchSelectNew.Count + 1)
					Write-Host $lineFromSearchResult
					$lastAnimeName = $lineFromSearchResult
					[Console]::SetCursorPosition($searchInputText.Length, 0)
				} else {
					$dictForSearchSelectNew.Add($lastAnimeName, $lineFromSearchResult)
				}
			} else {
				$searchAnimeSelectParameters.dictForSelect = $dictForSearchSelectNew
				[System.Threading.Thread]::Sleep(50)
			}
		} catch {
			[System.Threading.Thread]::Sleep(50)
		}

		continue
	}

	$key = [Console]::ReadKey()

	if ($key.Key -eq [System.ConsoleKey]::Enter -and $searchAnimeSelectParameters.dictForSelect.Count -gt 0) {
		[Console]::SetCursorPosition(0, 1)
		$searchAnimeSelectParameters.dictForSelect['...'] = $null
		$animeNameFromSearch = . "$PSScriptRoot/helpers/select.ps1" $searchAnimeSelectParameters
		if ($animeNameFromSearch -eq '...') {
			$searchAnimeSelectParameters.dictForSelect.Remove('...')
			$favoriteAnimes = . "$PSScriptRoot/helpers/favorite_management/get_favorites.ps1"
			[Console]::SetCursorPosition(0, 1);
			foreach ($pair in $searchAnimeSelectParameters.dictForSelect.GetEnumerator()) {
				$animePairKey = $pair.Key
				if ($null -ne $favoriteAnimes[$animePairKey]) {
					$animePairKey = '★ ' + $animePairKey
				}

				Write-Host $animePairKey
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
		if (($null -ne $requestAnimeProcess) -and (-not $requestAnimeProcess.HasExit)) {
			$requestAnimeProcess.Close()
		}

		$requestAnimeProcess = Start-Process -FilePath pwsh.exe -ArgumentList "-File `"`"$PSScriptRoot\helpers\request_anime_by_name.ps1`"`" -inputTextFromSearchScript `"$searchInputText`" -rememberMeToken `"$rememberMeToken`"" -RedirectStandardOutput $pathToSearchOutputLog -NoNewWindow -PassThru
	}
}

$searchLogStringReader.Close()
$searchLogFileStream.Close()