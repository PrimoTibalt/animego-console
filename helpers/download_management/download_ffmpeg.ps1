try {
	ffmpeg --help *> $null
} catch {
	Write-Host "You don't seem to have ffplay player installed, let me change that..."
	if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
		$downloadResult = Start-Process -FilePath pwsh.exe -Verb RunAs -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"" -PassThru
		while (-not $downloadResult.HasExited) {
			[System.Threading.Thread]::Yield()
		}
	} else {
		winget install --id=Gyan.FFmpeg -e
		return
	}

	. "$PSScriptRoot/../clean_console.ps1" 1
}

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")