$directoryUpscalerDestination = "$PSScriptRoot/../../temp/upscaler"
$zipUpscalerFileDestination = "$PSScriptRoot/../../temp/upscaler.zip"
if (Test-Path $directoryUpscalerDestination) {
	return
}

if (-not (Test-Path $zipUpscalerFileDestination)) {
	Write-Host 'Donwloading the upscaler'
	Invoke-RestMethod 'https://github.com/k4yt3x/video2x/releases/download/6.4.0/video2x-windows-amd64.zip' -OutFile $zipUpscalerFileDestination
	. "$PSScriptRoot/../clean_console.ps1" 1
}

try {
	New-Item $directoryUpscalerDestination -ItemType Directory *> $null
	Expand-Archive $zipUpscalerFileDestination $directoryUpscalerDestination -Force
	Remove-Item $zipUpscalerFileDestination -Force
} catch {
	Write-Host 'Something went wrong during upscaler download and unziping'
	Remove-Item $directoryUpscalerDestination
}