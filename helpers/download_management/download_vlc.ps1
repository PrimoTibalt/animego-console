if (-not $IsWindows) {
	Write-Host 'VLC player is required to watch. Install it with your package manager:'
	Write-Host '   sudo dnf install vlc      # Fedora'
	Write-Host '   sudo apt install vlc      # Debian/Ubuntu'
	Write-Host 'Click any button to return'
	[Console]::ReadKey($true) > $null
	& "$PSScriptRoot/../clean_console.ps1" 4
	return
}

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
	$pwshExecutable = . "$PSScriptRoot/../platform_management/get_pwsh_executable.ps1"
	$downloadResult = Start-Process -FilePath $pwshExecutable -Verb RunAs -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"" -PassThru
	while (-not $downloadResult.HasExited) {
		[System.Threading.Thread]::Yield()
	}
} else {
	Write-Host "You don't seem to have VLC player installed, let me change that..."
	winget install --id=VideoLAN.VLC -e
	& "$PSScriptRoot/../clean_console.ps1" 10 # Not very reliable ain't it
	return
}
