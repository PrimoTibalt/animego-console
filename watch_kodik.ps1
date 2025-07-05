param(
	[Parameter(Mandatory, Position = 0)]
	[string]$kodikEpisodePlayerUrl,
	[Parameter(Position = 1)]
	[bool]$wantToDownload
)

$kodikEpisodePlayerHeaders = @{
	'Referer'        = 'https://animego.one/'
	'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0'
	'Accept'         = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7'
}

$htmlKodikPlayer = Invoke-WebRequest $kodikEpisodePlayerUrl -Method 'Get' -Headers $kodikEpisodePlayerHeaders

if ($htmlKodikPlayer -match "urlParams = '(?<parameters>(.)*)';") {
	$kodikParameters = $Matches.parameters
}

$kodikParametersJsonObject = ConvertFrom-Json -InputObject $kodikParameters

if ($kodikEpisodePlayerUrl -match 'kodik\.info\/(?<type>(.)+)\/(?<video_id>[0-9]+)\/(?<hash>(.)+)\/') {
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
$kodikLinksResponse = Invoke-RestMethod -Uri 'https://kodik.info/ftor' -ContentType 'application/x-www-form-urlencoded' -Method POST -Body $formUrlEncoded
$kodikQualitiesOptions = New-Object System.Collections.SortedList
$kodikLinksResponse.links.psobject.properties | ForEach-Object { $kodikQualitiesOptions.Add([int]::Parse($_.Name), $_.Value.src) }
$encodedKodikLink = $kodikQualitiesOptions.GetByIndex($kodikQualitiesOptions.Count - 1)

# the funcitons below are just a rewritten by copilot version of decoding from python's library anime_parsers_ru
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

	# Base64 decoding requires padding
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

$decodedKodikLink = Convert-String $encodedKodikLink
$kodikVideoLink = "https:$decodedKodikLink"
. "$PSScriptRoot/helpers/open_vlc_player.ps1" -blob $kodikVideoLink $null $wantToDownload