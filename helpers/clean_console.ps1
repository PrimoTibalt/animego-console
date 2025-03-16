param(
	[Parameter(Position = 0, Mandatory)]
	$count
)

$currentLine = $Host.UI.RawUI.CursorPosition.Y
$consoleWidth = $Host.UI.RawUI.BufferSize.Width
$i = $currentLine - $count
try {
	for ($i; $i -le $currentLine + 1; $i++) {
		[Console]::SetCursorPosition(0, $i)
		[Console]::Write("{0,-$consoleWidth}" -f "")
	}
} catch {}

try {
	[Console]::SetCursorPosition(0, $currentLine - $count)
} catch {
	for ($i = 0; $i -lt $count; $i++) {
		try {
			[Console]::SetCursorPosition(0, $currentLine - $i)
		} catch {}
	}
}