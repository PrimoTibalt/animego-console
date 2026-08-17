if (-not $IsWindows) {
	$vlcFromPath = Get-Command vlc -ErrorAction SilentlyContinue
	if ($null -eq $vlcFromPath) {
		return $null
	}

	return $vlcFromPath.Source
}

$vlcWindowsPaths = @(
	'C:\Program Files\VideoLAN\VLC\vlc.exe'
	'C:\Program Files (x86)\VideoLAN\VLC\vlc.exe'
)

foreach ($vlcWindowsPath in $vlcWindowsPaths) {
	if (Test-Path $vlcWindowsPath) {
		return $vlcWindowsPath
	}
}

return $null
