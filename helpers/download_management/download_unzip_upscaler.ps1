$directoryUpscalerDestination = "$PSScriptRoot/../../temp/upscaler"
if (Test-Path $directoryUpscalerDestination) {
	return
}

if (-not $IsWindows) {
	$appImageUpscalerDestination = . "$PSScriptRoot/../platform_management/get_upscaler_path.ps1"
	Write-Host 'Donwloading the upscaler'
	try {
		New-Item $directoryUpscalerDestination -ItemType Directory *> $null
		Invoke-RestMethod 'https://github.com/k4yt3x/video2x/releases/download/6.4.0/Video2X-x86_64.AppImage' -OutFile $appImageUpscalerDestination
		chmod +x $appImageUpscalerDestination
	} catch {
		Write-Host 'Something went wrong during upscaler download'
		Remove-Item $directoryUpscalerDestination -Recurse -Force *> $null
	}

	& "$PSScriptRoot/../clean_console.ps1" 1
	return
}

$zipUpscalerFileDestination = "$PSScriptRoot/../../temp/upscaler.zip"
if (-not (Test-Path $zipUpscalerFileDestination)) {
	Write-Host 'Donwloading the upscaler'
	Invoke-RestMethod 'https://github.com/k4yt3x/video2x/releases/download/6.4.0/video2x-windows-amd64.zip' -OutFile $zipUpscalerFileDestination
	& "$PSScriptRoot/../clean_console.ps1" 1
}

try {
	New-Item $directoryUpscalerDestination -ItemType Directory *> $null
	Expand-Archive $zipUpscalerFileDestination $directoryUpscalerDestination -Force
	Remove-Item $zipUpscalerFileDestination -Force
} catch {
	Write-Host 'Something went wrong during upscaler download and unziping'
	Remove-Item $directoryUpscalerDestination -Recurse -Force *> $null
}
