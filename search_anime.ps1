Add-Type -AssemblyName 'System.Net'

$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
Clear-Host

$text = ''
$dict = [ordered]@{}
while ($true) {
	[Console]::SetCursorPosition($text.Length, 0)
	$key = $Host.UI.RawUI.ReadKey("IncludeKeyDown");
	if ($key.VirtualKeyCode -eq '13') {
		$animeLink = ./helpers/select.ps1 $dict
		./select_episode.ps1 "https://animego.one$animeLink"
		continue
	}

	if ($key.VirtualKeyCode -eq '0') {
		return
	}

	if ($key.VirtualKeyCode -eq '8') {
		if (-not [string]::IsNullOrEmpty($text)) {
			[Console]::Write("{0,-1}" -f "")
			$text = $text.Substring(0, $text.Length - 1)
		}
		continue
	}

	$text = $text + $key.Character
	if ($text.Length -ge 4) {
		if ($dict.Count -gt 0) {
			[Console]::SetCursorPosition(0, $dict.Count)
			$toDeleteLines = $dict.Count - 1
			./helpers/clean_console.ps1 $toDeleteLines
		}

		$queryString = "search/all?type=small&q=$text&_=1741983593650"
		$html = ./helpers/try_request.ps1 $queryString 
		$data = ./tool/GetEpisodes.exe "search" $html 2> ./temp/log.txt
		if ($null -ne $data) {
			foreach ($pair in $data.Split(';')) {
				$pair = $pair.Split(',')
				$dict[$pair[0]] = $pair[1]
			}
		}

		[Console]::SetCursorPosition(0, 1);
		foreach($pair in $dict.GetEnumerator()) {
			Write-Host $pair.Key
		}
	}
}