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

while ($true) {
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

	$dictOfDownloadedDubs = [ordered]@{}
	Get-ChildItem $selectedAnimeDirectory -Directory | ForEach-Object {
		$dictOfDownloadedDubs[$_.Name] = $_.FullName
	}

	if ($dictOfDownloadedDubs.Count -eq 1) {
		$selectedDubEnumerator = $dictOfDownloadedDubs.GetEnumerator()
		$selectedDubEnumerator.MoveNext() *> $null
		$selectedDubFolderName = $selectedDubEnumerator.Current.Key
		$selectedDubFolder = $selectedDubEnumerator.Current.Value
	}
	else {
		$animeDubFolderSelectParameters = New-Object SelectParameters
		$animeDubFolderSelectParameters.dictForSelect = $dictOfDownloadedDubs
		$animeDubFolderSelectParameters.showMessageOnSelect = $false
		$animeDubFolderSelectParameters.returnKey = $true
		$selectedDubFolderName = . "$PSScriptRoot/helpers/select.ps1" $animeDubFolderSelectParameters
		$selectedDubFolder = $dictOfDownloadedDubs[$selectedDubFolderName]
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
		$selectedEpisodeNumber = . "$PSScriptRoot/helpers/select.ps1" $animeDownloadedEpisodeSelectPrameters
		$selectedEpisodePath = $dictOfDownloadedEpisodes.$selectedEpisodeNumber

		if ($selectedEpisodeNumber -eq '__') {
			break
		}

		$vlc = 'C:\Program Files\VideoLAN\VLC\vlc.exe'
		& $vlc $selectedEpisodePath --fullscreen
		. "$PSScriptRoot/helpers/state_management/set_last_dubbing.ps1" $selectedDubFolderName
		. "$PSScriptRoot/helpers/state_management/add_episode.ps1" $selectedEpisodeNumber
		. "$PSScriptRoot/helpers/watched_management/synchronize_from_state.ps1"
	}
}