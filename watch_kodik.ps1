param(
	[Parameter(Mandatory, Position = 0)]
	[string]$kodikEpisodePlayerUrl,
	[Parameter(Position = 1)]
	[bool]$wantToDownload
)

$kodikPlayerHost = ([Uri]::new($kodikEpisodePlayerUrl)).Host
$kodikPlayerOrigin = "https://$kodikPlayerHost"

$kodikEpisodePlayerHeaders = @{
	'Referer'        = 'https://animego.me/'
	'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0'
	'Accept'         = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7'
}

$htmlKodikPlayer = (Invoke-WebRequest $kodikEpisodePlayerUrl -Method 'Get' -Headers $kodikEpisodePlayerHeaders).Content

if ($htmlKodikPlayer -notmatch "urlParams = '(?<parameters>(.)*)';") {
	Write-Host 'Kodik player did not return its parameters. Click any button to return'
	[Console]::ReadKey($true) > $null
	return
}

$kodikParametersJsonObject = ConvertFrom-Json -InputObject $Matches.parameters

if ($kodikEpisodePlayerUrl -match '/(?<type>[a-z]+)/(?<video_id>[0-9]+)/(?<hash>[0-9a-zA-Z]+)/') {
	$kodikParametersJsonObject | Add-Member -Name 'hash' -MemberType NoteProperty -Value $Matches.hash
	$kodikParametersJsonObject | Add-Member -Name 'id' -MemberType NoteProperty -Value $Matches.video_id
	$kodikParametersJsonObject | Add-Member -Name 'type' -MemberType NoteProperty -Value $Matches.type
	$kodikParametersJsonObject | Add-Member -Name 'bad_user' -MemberType NoteProperty -Value 'true'
	$kodikParametersJsonObject | Add-Member -Name 'cdn_is_working' -MemberType NoteProperty -Value 'true'
	$kodikParametersJsonObject | Add-Member -Name 'info' -MemberType NoteProperty -Value '{"advImps":{}}'
	$kodikParametersJsonObject = $kodikParametersJsonObject | `
		Select-Object * -ExcludeProperty translations | `
		Select-Object * -ExcludeProperty advert_debug | `
		Select-Object * -ExcludeProperty min_age | `
		Select-Object * -ExcludeProperty first_url
}

$kodikParametersMap = @{}
$kodikParametersJsonObject.psobject.properties | ForEach-Object { $kodikParametersMap[$_.Name] = $_.Value }
$formUrlEncoded = ($kodikParametersMap.GetEnumerator() | ForEach-Object {"$($_.Key)=$($_.Value)"}) -join '&'

$kodikFtorHeaders = @{
	'Referer'          = $kodikEpisodePlayerUrl
	'Origin'           = $kodikPlayerOrigin
	'User-Agent'       = $kodikEpisodePlayerHeaders['User-Agent']
	'x-requested-with' = 'XMLHttpRequest'
}

$kodikLinksResponse = Invoke-RestMethod -Uri "$kodikPlayerOrigin/ftor" -ContentType 'application/x-www-form-urlencoded' -Method POST -Headers $kodikFtorHeaders -Body $formUrlEncoded

$kodikQualitiesOptions = New-Object System.Collections.SortedList
$kodikLinksResponse.links.psobject.properties | ForEach-Object {
	$kodikQualitySource = $_.Value
	if ($kodikQualitySource -is [System.Object[]]) {
		$kodikQualitySource = $kodikQualitySource[0]
	}

	if ($null -ne $kodikQualitySource -and -not [string]::IsNullOrEmpty($kodikQualitySource.src)) {
		$kodikQualitiesOptions.Add([int]::Parse($_.Name), $kodikQualitySource.src)
	}
}

if ($kodikQualitiesOptions.Count -eq 0) {
	Write-Host 'Kodik returned no playable links. Click any button to return'
	[Console]::ReadKey($true) > $null
	return
}

$encodedKodikLink = $kodikQualitiesOptions.GetByIndex($kodikQualitiesOptions.Count - 1)

$script:_cryptStep = 18

function Convert-Char {
	param ($letter, $num)

	$alph = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	$low = ($letter -cmatch "[a-z]")

	$upper = [char]::ToUpper($letter)
	if ($alph.Contains($upper)) {
		$ch = $alph[($alph.IndexOf($upper) + $num) % $alph.Length]
		return $low ? [char]::ToLower($ch) : $ch
	}	else {
		return $letter
	}
}

function Convert-String {
	param (
		[Parameter(Mandatory, Position = 0)]
		[string]$encodedUrl
	)

	function Base64-Decode {
		param ([string]$encodedString)

		$padding = (4 - ($encodedString.Length % 4)) % 4
		$encodedString += "=" * $padding
		try {
			$decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedString))
			return $decoded
		} catch {
			return $null
		}
	}

	if ($null -ne $script:_cryptStep) {
		$cryptedUrl = ($encodedUrl.ToCharArray() | ForEach-Object { Convert-Char $_ $script:_cryptStep }) -join ""
		$result = Base64-Decode $cryptedUrl
		if ($result -match "mp4:hls:manifest") { return $result }
	}

	for ($rot = 0; $rot -lt 26; $rot++) {
		$cryptedUrl = ($encodedUrl.ToCharArray() | ForEach-Object { Convert-Char $_ $rot }) -join ""
		$result = Base64-Decode $cryptedUrl
		if ($result -match "mp4:hls:manifest") {
			$script:_cryptStep = $rot
			return $result
		}
	}

	throw "Decryption Failure"
}

if ($encodedKodikLink.Contains('//')) {
	$decodedKodikLink = $encodedKodikLink
} else {
	$decodedKodikLink = Convert-String $encodedKodikLink
}

if ($decodedKodikLink.StartsWith('//')) {
	$kodikVideoLink = "https:$decodedKodikLink"
} else {
	$kodikVideoLink = $decodedKodikLink
}

. "$PSScriptRoot/helpers/open_player.ps1" -blob $kodikVideoLink "$kodikPlayerOrigin/" $wantToDownload
