param(
	[Parameter(Position = 0, Mandatory)]
	$originalLink,
	[Parameter(Position = 1)]
	$dataId
)

$originalLink -match "-(?<number>\d\d\d\d)" > $null
$number = $Matches.number
$cookie = $null
if ($null -ne $dataId) {
	$cookie = "episode_video=$dataId;"
}

return ./helpers/try_request.ps1 "anime/$number/player?_allow=true" $originalLink $cookie