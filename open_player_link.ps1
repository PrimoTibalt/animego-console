param(
	[Parameter(Position = 0, Mandatory)]
	$originalLink,
	[Parameter(Position = 1)]
	$dataId
)

$originalLink = $originalLink.Trim()

if ($null -ne $dataId) {
	return . "$PSScriptRoot/helpers/try_request.ps1" "player/videos/$dataId" $originalLink
}

if ($originalLink -notmatch '-(?<number>\d+)$') {
	return $null
}

$number = $Matches.number

return . "$PSScriptRoot/helpers/try_request.ps1" "player/$number" $originalLink
