$favoriteAnimesFilePath = "$PSScriptRoot/../../temp/favorites.json"
if (-not (Test-Path -Path $favoriteAnimesFilePath)) {
	New-Item -Path $favoriteAnimesFilePath -ItemType File -Value '{}' -Force > $null
}

if ($null -eq $favoriteAnimes) {
	$favoriteAnimes = [ordered]@{}
	$favoriteAnimesJsonObject = Get-Content $favoriteAnimesFilePath | ConvertFrom-Json
	Get-Member -InputObject $favoriteAnimesJsonObject -MemberType NoteProperty | ForEach-Object { 
		$favoriteAnimeName = $_.Name
		$favoriteAnimes[$favoriteAnimeName] = $favoriteAnimesJsonObject.$favoriteAnimeName
	} > $null
}

return $favoriteAnimes