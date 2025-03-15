Add-Type -AssemblyName 'System.Net'

[Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
chcp 65001
Clear-Host

$text = ''
$dict = [ordered]@{}
while ($true) {
	if ($text.Length -ge 4) {
		if ($dict.Count -gt 0) {
			[Console]::SetCursorPosition(0, $dict.Count)
			$toDeleteLines = $dict.Count - 1
			./helpers/clean_console.ps1 $toDeleteLines
		}

		$queryString = "search/all?type=small&q=$text&_=1741983593650"
		$html = ./helpers/try_request.ps1 $queryString 
		$content = [System.Net.WebUtility]::HtmlDecode($html)
		$data = ./tool/GetEpisodes.exe "search" $content 2> ./temp/log.txt
		if (-not [string]::IsNullOrWhiteSpace($data)) {
			$dict = [ordered]@{}
			foreach ($pair in $data.Split(';')) {
				$pair = $pair.Split('||')
				$dict[$pair[0]] = $pair[1]
			}
		}

		[Console]::SetCursorPosition(0, 1);
		foreach($pair in $dict.GetEnumerator()) {
			Write-Host $pair.Key
		}
	}

	[Console]::SetCursorPosition(0, 0)
	[Console]::Write("{0, 120}" -f "")
	[Console]::SetCursorPosition(0, 0)
	[Console]::Write("$text")
	$key = [Console]::ReadKey($true)

	if ($key.Key -eq [System.ConsoleKey]::Enter -and $dict.Count -gt 0) {
		[Console]::SetCursorPosition(0, 1)
		$animeLink = ./helpers/select.ps1 $dict $null $false
		./select_episode.ps1 "https://animego.one$animeLink"
		Clear-Host
		continue
	}

	if ($key.Key -eq [System.ConsoleKey]::Backspace) {
		if (-not [string]::IsNullOrEmpty($text)) {
			[Console]::Write("{0,-1}" -f "")
			$text = $text.Substring(0, $text.Length - 1)
		}
		continue
	}

	$text = $text + $key.KeyChar
}