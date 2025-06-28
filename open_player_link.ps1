param(
	[Parameter(Position = 0, Mandatory)]
	$originalLink,
	[Parameter(Position = 1)]
	$dataId
)

$originalLink = $originalLink.Trim()
$originalLink -match "-(?<number>\d{2,4})$" > $null
$number = $Matches.number
$cookie = $null
if ($null -ne $dataId) {
	$cookie = "episode_video=$dataId"
}

return . "$PSScriptRoot/helpers/try_request.ps1" "anime/$number/player?_allow=true" $originalLink $cookie