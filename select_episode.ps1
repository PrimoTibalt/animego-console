param(
	[Parameter(Mandatory, Position = 0)]
	[string]$link,
	[Parameter(Position = 1)]
	[System.Collections.Specialized.OrderedDictionary]$dict
)

Add-Type -AssemblyName 'System.Net'
$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding

$html = ./open_player_link.ps1 $link
if ($null -eq $html) {
	Write-Host 'Unable to fetch player link, site is down or antiddos kicked in'
	return
}

$episodes = ./tool/GetEpisodes.exe 'episodes' $html 2> ./temp/log.txt
if ([string]::IsNullOrEmpty($episodes)) {
	Write-Host 'No episodes found'
	return
}

$episodes = $episodes.Split(';')
if ($episodes.Count -lt 0) {
	Write-Error 'No episodes found'
	return $null
}

$dict = [ordered]@{}
foreach ($episode in $episodes) {
	$pair = $episode.Split(',')
	$key = [System.Int32]::Parse($pair[0])
	$value = [System.Int32]::Parse($pair[1])
	$dict.Add($key, $value)
}

$dataId = ./helpers/select.ps1 $dict 'Select episode:'
if ($null -ne $dataId) {
	Write-Host "Selected episode with data id $dataId"
	./select_dubbing.ps1 $link $dataId
	./select_episode.ps1 $link
} else {
	return $null
}