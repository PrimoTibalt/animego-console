$text = ''
$foundAnimeMapToHrefMap = [ordered]@{}
while ($true) {
	if ($text.Length -ge 4) {
		if ($foundAnimeMapToHrefMap.Count -gt 0) {
			[Console]::SetCursorPosition(0, $foundAnimeMapToHrefMap.Count)
			$toDeleteLines = $foundAnimeMapToHrefMap.Count - 1
			. "$PSScriptRoot/helpers/clean_console.ps1" $toDeleteLines
		}

		$queryString = "search/all?type=small&q=$text&_=1741983593650"
		$html = . "$PSScriptRoot/helpers/try_request.ps1" $queryString 
		$content = [System.Net.WebUtility]::HtmlDecode($html)
		$data = . "$PSScriptRoot/tool/GetEpisodes.exe" 'search' $content 2> "$PSScriptRoot/temp/log.txt"
		if (-not [string]::IsNullOrWhiteSpace($data)) {
			$foundAnimeMapToHrefMap = [ordered]@{}
			foreach ($pair in $data.Split(';')) {
				$pair = $pair.Split('||')
				$foundAnimeMapToHrefMap[$pair[0]] = $pair[1]
			}
		}

		[Console]::SetCursorPosition(0, 1);
		foreach($pair in $foundAnimeMapToHrefMap.GetEnumerator()) {
			Write-Host $pair.Key
		}
	}

	$widthOfConsole = $Host.UI.RawUI.BufferSize.Width
	[Console]::SetCursorPosition(0, 0)
	[Console]::Write("{0, $widthOfConsole}" -f "")
	[Console]::SetCursorPosition(0, 0)
	[Console]::Write("$text")
	$key = [Console]::ReadKey($true)

	if ($key.Key -eq [System.ConsoleKey]::Enter -and $foundAnimeMapToHrefMap.Count -gt 0) {
		[Console]::SetCursorPosition(0, 1)
		$name = . "$PSScriptRoot/helpers/select.ps1" $foundAnimeMapToHrefMap $null $false $true
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

	if ($key.Key -eq [System.ConsoleKey]::Backspace) {
		if (-not [string]::IsNullOrEmpty($text)) {
			[Console]::Write("{0,-1}" -f "")
			$text = $text.Substring(0, $text.Length - 1)
		}
		continue
	}

	if ($key.KeyChar -eq '`') {
		break
	}

	$text = $text + $key.KeyChar
}