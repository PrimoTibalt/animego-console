param(
	[Parameter(Position = 0, Mandatory)]
	$count
)

$currentLine = $Host.UI.RawUI.CursorPosition.Y
$consoleWidth = $Host.UI.RawUI.BufferSize.Width
$i = $currentLine - $count
for ($i; $i -le $count; $i++) {
	[Console]::SetCursorPosition(0, ($currentLine - $i))
	[Console]::Write("{0,-$consoleWidth}" -f " ")
}

[Console]::SetCursorPosition(0, ($currentLine - $i + 1))