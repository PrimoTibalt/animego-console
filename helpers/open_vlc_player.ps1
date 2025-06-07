param(
	[Parameter(Position = 0, Mandatory)]
	[string] $blob
)

$agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 Edg/133.0.0.0" 
$referrer = "https://aniboom.one/"
$vlc = "C:\Program Files\VideoLAN\VLC\vlc.exe"

& $vlc --http-referrer $referrer --http-user-agent $agent $blob --fullscreen