param(
	[Parameter(Mandatory, Position = 0)]
	[string]$cvnPlayerEpisodeLink,
	[Parameter(Position = 1)]
	[bool]$wantToDownload
)

$episodeNumberFromUrl = [int]::Parse($cvnPlayerEpisodeLink[$cvnPlayerEpisodeLink.Length - 1])

$cvnPlayerEpisodeHeaders = @{
	'Referer'        = 'https://animego.me/'
	'User-Agent'     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0'
	'Accept'         = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7'
}

$cvnPlayerEpisodeResponse = Invoke-RestMethod -Uri $cvnPlayerEpisodeLink -Headers $cvnPlayerEpisodeHeaders

$cvnPlayerEpisodeData = . "$PSScriptRoot/helpers/html_parsers/cdn_response_parsers/get_id_and_dub.ps1" $cvnPlayerEpisodeResponse

$publisherIdOfAnime = $cvnPlayerEpisodeData.PublisherId
$aggregatorOfAnime = $cvnPlayerEpisodeData.Aggregator
$idOfAnimeOnCvn = $cvnPlayerEpisodeData.AnimeId
$priorityDub = $cvnPlayerEpisodeData.PriorityDub

try {
	$plapiResultJsonContent = Invoke-RestMethod -Uri "https://plapi.cdnvideohub.com/api/v1/player/sv/playlist?pub=$publisherIdOfAnime&aggr=$aggregatorOfAnime&id=$idOfAnimeOnCvn" -Headers $cvnPlayerEpisodeHeaders
	$dubItemDetails = $plapiResultJsonContent.items | Where-Object { ($_.voiceStudio -eq $priorityDub) -and ($_.episode -eq $episodeNumberFromUrl) }
	if ($null -eq $dubItemDetails) {
		$dubItemDetails = $plapiResultJsonContent.items[0]
		Write-Host 'Could not find preferred dub. Chose random. Click any button to continue'
		Read-Host
		. "$PSScriptRoot/helpers/clean_console.ps1" 2
	}
} catch {
	Write-Host 'CVN is unavailable right now. Click any button to return'
	Read-Host
	. "$PSScriptRoot/helpers/clean_console.ps1" 2
	return $true
}

$vkIdOfAnEpisode = $dubItemDetails.vkId
$plapiVideoMetadataResultJsonContent = Invoke-RestMethod -Uri "https://plapi.cdnvideohub.com/api/v1/player/sv/video/$vkIdOfAnEpisode" -Headers $cvnPlayerEpisodeHeaders
$videoQualityHighest = $null
$videoQualityOptions = @('mpeg4kUrl', 'mpeg2kUrl', 'mpegQhdUrl', 'mpegFullHdUrl', 'mpegHighUrl', 'mpegMediumUrl', 'mpegLowUrl')
foreach ($videoQualityOption in $videoQualityOptions) {
	if (-not [string]::IsNullOrEmpty($plapiVideoMetadataResultJsonContent.sources.$videoQualityOption)) {
		$videoQualityHighest = $plapiVideoMetadataResultJsonContent.sources.$videoQualityOption
		break
	}
}

if ($null -ne $videoQualityHighest) {
	. "$PSScriptRoot/helpers/open_vlc_player.ps1" $videoQualityHighest 'https://player.cdnvideohub.com/' $wantToDownload
} else {
	Write-Host 'Could not find hls urls to video, nothing to play. Click any button to return'
	Read-Host
	. "$PSScriptRoot/helpers/clean_console.ps1" 2
}