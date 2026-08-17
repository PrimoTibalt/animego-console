param(
	[Parameter(Position = 0, Mandatory)]
	[int]$topLine
)

if ($topLine -lt 0) {
	$topLine = 0
}

$currentLine = $Host.UI.RawUI.CursorPosition.Y
$consoleWidth = $Host.UI.RawUI.BufferSize.Width
try {
	for ($lineToClean = $topLine; $lineToClean -le $currentLine + 1; $lineToClean++) {
		[Console]::SetCursorPosition(0, $lineToClean)
		[Console]::Write("{0,-$consoleWidth}" -f "")
	}
} catch {}

try {
	[Console]::SetCursorPosition(0, $topLine)
} catch {}
