param(
	[Parameter(Mandatory, Position = 0)]
	[String]$link
)

Clear-Host
Add-Type -AssemblyName 'System.Net'

$link -match "-(?<number>\d\d\d\d)" > $null
$headers = @{
	'x-requested-with' = 'XMLHttpRequest'
	'Referer'        = $link
	'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 Edg/133.0.0.0'
	'Accept'         = 'application/json, text/javascript, */*; q=0.01'
}

$links = @( 'animego.me', 'animego.club', 'animego.org' )
foreach ($postfixVariant in $links) {
	$playerLink = "https://$postfixVariant/anime/" + $Matches.number + '/player?_allow=true'
	try {
		$response = Invoke-RestMethod -Uri $playerLink -Method 'Get' -Headers $headers -TimeoutSec 1
		if ($response.status -eq 'success') {
			Write-Output "Successfuly retrieved from $postfixVariant"
			$html = $response.content
			break;
		}
	}
	catch {
		Write-Output "$postfixVariant did not succeed"
		continue;
	}
}

$episodes = ./tool/GetEpisodes.exe 'episodes' $html
$episodes = $episodes.Split(';')
$dict = [ordered]@{}
foreach ($episode in $episodes) {
	$pair = $episode.Split(',')
	$key = [System.Int32]::Parse($pair[0])
	$value = [System.Int32]::Parse($pair[1])
	$dict.Add($key, $value)
}

& .\select.ps1 $dict | Write-Output