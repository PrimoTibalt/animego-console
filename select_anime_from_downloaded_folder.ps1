$listOfReverseSubstitution = @{
	'@#' = '/'
	'@;' = '\'
	'@&' = ':'
	'@*' = '?'
	'#@' = '"'
	';@' = '<'
	'&@' = '>'
	'*@' = '|'
}

while ($true) { # Loop for anime names
	#loop to choose anime from downloaded
	$dictOfDownloadedAnimes = [ordered]@{}
	Get-ChildItem "$PSScriptRoot/temp/animes" -Directory | ForEach-Object {
		$animeNameSubstituted = $_.Name
		foreach ($reverseSubstitution in $listOfReverseSubstitution.GetEnumerator()) {
			$animeNameSubstituted = $animeNameSubstituted.Replace($reverseSubstitution.Key, $reverseSubstitution.Value)
		}

		$dictOfDownloadedAnimes[$animeNameSubstituted] = $_.FullName
	}

	$animeFolderSelectParameters = New-Object SelectParameters
	$animeFolderSelectParameters.dictForSelect = $dictOfDownloadedAnimes
	$animeFolderSelectParameters.showMessageOnSelect = $false
	$animeFolderSelectParameters.returnKey = $true
	$animeFolderSelectParameters.actionOnF = [Action[[string],[string]]]{ # upscale all downloaded files synchronously
		param(
			[string]$downloadedAnimeName,
			[string]$downloadedAnimeDirectory
		)

		$dubbingOfDownloadedAnimeDirectory = (Get-ChildItem $downloadedAnimeDirectory -Directory)[0].FullName
		$dictOfDownloadedEpisodesForUpscaling = [ordered]@{}
		Get-ChildItem $dubbingOfDownloadedAnimeDirectory | ForEach-Object {
			$dictOfDownloadedEpisodesForUpscaling[$_.Name] = $_.FullName
		}

		foreach ($animeEpisodeForUpscaling in $dictOfDownloadedEpisodesForUpscaling.GetEnumerator()) {
			$fileFullNameForUpscaling = $animeEpisodeForUpscaling.Value
			Write-Host "$fileFullNameForUpscaling is upscaling"
			. "$PSScriptRoot/helpers/upscaling_management/upscale_video.ps1" $fileFullNameForUpscaling
		}

		$countOfUpscaledFiles = $dictOfDownloadedEpisodesForUpscaling.Count
		. "$PSScriptRoot/helpers/clean_console.ps1" $countOfUpscaledFiles
		Write-Host "Total of $countOfUpscaledFiles files was upscaled. Click any button to continue..."
		[Console]::ReadKey($true)
		. "$PSScriptRoot/helpers/clean_console.ps1" 1
	}
	$selectedAnimeName = . "$PSScriptRoot/helpers/select.ps1" $animeFolderSelectParameters
	if ($selectedAnimeName -eq '__') {
		return
	}

	$selectedAnimeDirectory = $dictOfDownloadedAnimes[$selectedAnimeName]
	$hrefFromState = . "$PSScriptRoot/helpers/watched_management/synchronize_to_state.ps1" $selectedAnimeName
	if ([string]::IsNullOrEmpty($hrefFromState)) {
		$hrefFromFile = Get-Content "$selectedAnimeDirectory/href.txt"
		. "$PSScriptRoot/helpers/state_management/create_state.ps1" $selectedAnimeName $hrefFromFile
	}

	$wantToBreakFromEpisodesSelection = $false
	while ($true) {
		# Loop for dubbing
		$dictOfDownloadedDubs = [ordered]@{}
		Get-ChildItem $selectedAnimeDirectory -Directory | ForEach-Object {
			$dictOfDownloadedDubs[$_.Name] = $_.FullName
		}

		if ($dictOfDownloadedDubs.Count -eq 1) {
			if ($wantToBreakFromEpisodesSelection) {
				break
			}

			$selectedDubEnumerator = $dictOfDownloadedDubs.GetEnumerator()
			$selectedDubEnumerator.MoveNext() *> $null
			$selectedDubFolderName = $selectedDubEnumerator.Current.Key
			$selectedDubFolder = $selectedDubEnumerator.Current.Value
		} elseif ($dictOfDownloadedDubs.Count -gt 1) {
			$animeDubFolderSelectParameters = New-Object SelectParameters
			$animeDubFolderSelectParameters.dictForSelect = $dictOfDownloadedDubs
			$animeDubFolderSelectParameters.showMessageOnSelect = $false
			$animeDubFolderSelectParameters.returnKey = $true
			$selectedDubFolderName = . "$PSScriptRoot/helpers/select.ps1" $animeDubFolderSelectParameters
			if ($selectedDubFolderName -eq '__') {
				break
			}
			$selectedDubFolder = $dictOfDownloadedDubs[$selectedDubFolderName]
		} else {
			Write-Host 'No dubs where found. Click any button to return...'
			[Console]::ReadKey($true)
			. "$PSScriptRoot/helpers/clean_console.ps1" 1
			break
		}

		while ($true) {
			$dictOfDownloadedEpisodes = [ordered]@{}
			Get-ChildItem $selectedDubFolder | ForEach-Object {
				$episodeNameWithoutExtension = [int]::Parse($_.Name.Replace('.mp4', [string]::Empty))
				$dictOfDownloadedEpisodes.Add($episodeNameWithoutExtension, $_.FullName)
			}

			$lastEpisode = . "$PSScriptRoot/helpers/state_management/get_episode.ps1"
			$animeDownloadedEpisodeSelectPrameters = New-Object SelectParameters
			$animeDownloadedEpisodeSelectPrameters.dictForSelect = $dictOfDownloadedEpisodes
			$animeDownloadedEpisodeSelectPrameters.showMessageOnSelect = $false
			$animeDownloadedEpisodeSelectPrameters.returnKey = $true
			if ($null -ne $lastEpisode) {
				$animeDownloadedEpisodeSelectPrameters.preselectedValue = [int]::Parse($lastEpisode)
			}
			$animeDownloadedEpisodeSelectPrameters.actionOnF = [Action[[string], [string]]] {
				param(
					[string]$nameOfAFile,
					[string]$pathToAFile
				)

				. "$PSScriptRoot/helpers/upscaling_management/upscale_video.ps1" $pathToAFile
			}
			$selectedEpisodeNumber = . "$PSScriptRoot/helpers/select.ps1" $animeDownloadedEpisodeSelectPrameters
			$selectedEpisodePath = $dictOfDownloadedEpisodes.$selectedEpisodeNumber

			if ($selectedEpisodeNumber -eq '__') {
				$wantToBreakFromEpisodesSelection = $true
				break
			}

			$vlc = 'C:\Program Files\VideoLAN\VLC\vlc.exe'
			& $vlc $selectedEpisodePath --fullscreen
			. "$PSScriptRoot/helpers/state_management/set_last_dubbing.ps1" $selectedDubFolderName
			. "$PSScriptRoot/helpers/state_management/add_episode.ps1" $selectedEpisodeNumber
			. "$PSScriptRoot/helpers/watched_management/synchronize_from_state.ps1"
		}
	}
}