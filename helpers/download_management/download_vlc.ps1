if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
	$downloadResult = Start-Process -FilePath pwsh.exe -Verb RunAs -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"" -PassThru
	while (-not $downloadResult.HasExited) {
		[System.Threading.Thread]::Yield()
	}
} else {
	Write-Host "You don't seem to have VLC player installed, let me change that..."
	winget install --id=Gyan.FFmpeg -e
	& "$PSScriptRoot/../clean_console.ps1" 10 # Not very reliable ain't it
	return
}