param(
	[Parameter(Mandatory, Position = 0)]
	$pathToVideoForUpscaling
)

if (-not (Test-Path $pathToVideoForUpscaling)) {
	Write-Host "$pathToVideoForUpscaling doesn't exist. Click any button..."
	[Console]::ReadKey($true)
	. "$PSScriptRoot/../clean_console.ps1" 1
}

$upscalerExePath = "$PSScriptRoot/../../temp/upscaler/video2x.exe"
$upscalerLogPath = "$PSScriptRoot/../../temp/upscaler_log.txt"
if (-not (Test-Path $upscalerExePath)) {
	. "$PSScriptRoot/../download_management/download_unzip_upscaler.ps1"
	Write-Host 'Click any button to continue'
	[Console]::ReadKey($true) *> $null
	. "$PSScriptRoot/../clean_console.ps1" 1
}

$upscalerInitialOutputPath = "$PSScriptRoot/../../temp/upscaled.mp4"
if (Test-Path $upscalerInitialOutputPath) {
	Remove-Item $upscalerInitialOutputPath -Force *> $null
}

if (Test-Path $upscalerLogPath) {
	Remove-Item $upscalerLogPath -Force *> $null
}

New-Item $upscalerLogPath -Force *> $null
$upscalingProcess = Start-Process -FilePath $upscalerExePath -ArgumentList "-i `"$pathToVideoForUpscaling`" -o $upscalerInitialOutputPath -p realcugan --realcugan-threads 4096 -s 2 -d 0" -NoNewWindow -RedirectStandardOutput $upscalerLogPath -PassThru

$upscalerFileStream = New-Object System.IO.FileStream($upscalerLogPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$upscalerReader = New-Object System.IO.StreamReader($upscalerFileStream)
while (-not $upscalingProcess.HasExited) {
	try {
		$lineFromUpscalerToProcess = $upscalerReader.ReadLine()
		if ((-not [string]::IsNullOrWhiteSpace($lineFromUpscalerToProcess)) -and $lineFromUpscalerToProcess.Contains('frame=')) {
			Write-Host $lineFromUpscalerToProcess
			[Console]::SetCursorPosition(0, $Host.UI.RawUI.CursorPosition.Y - 1)
		}
	} catch {
		Write-Host 'You failed in reading logs'
	}
}

. "$PSScriptRoot/../clean_console.ps1" 1
Move-Item $upscalerInitialOutputPath $pathToVideoForUpscaling -Force