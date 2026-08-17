try {
	ffmpeg --help *> $null
} catch {
	if (-not $IsWindows) {
		Write-Host 'ffmpeg is required to play and download this player. Install it with your package manager:'
		Write-Host '   sudo dnf install ffmpeg      # Fedora'
		Write-Host '   sudo apt install ffmpeg      # Debian/Ubuntu'
		Write-Host 'Click any button to return'
		[Console]::ReadKey($true) > $null
		. "$PSScriptRoot/../clean_console.ps1" 4
		return
	}

	Write-Host "You don't seem to have ffplay player installed, let me change that..."
	if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
		$pwshExecutable = . "$PSScriptRoot/../platform_management/get_pwsh_executable.ps1"
		$downloadResult = Start-Process -FilePath $pwshExecutable -Verb RunAs -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"" -PassThru
		while (-not $downloadResult.HasExited) {
			[System.Threading.Thread]::Yield()
		}
	} else {
		winget install --id=Gyan.FFmpeg -e
		return
	}

	. "$PSScriptRoot/../clean_console.ps1" 1
}

if ($IsWindows) {
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}
