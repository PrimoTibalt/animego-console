# Cross-platform (Linux) transformation notes

Audit of everything in this repo that assumes Windows, with a suggested fix for each.

Every claim below was checked empirically against **PowerShell 7.6.5 on Fedora Linux** (`pwsh`, not `pwsh.exe`) — either by running the API in isolation or by driving the real scripts. Items are marked **BLOCKER** (feature is dead on Linux), **BUG** (actively breaks something else), or **COSMETIC**.

---

## 1. What already works — do not rewrite this

A large part of the app is already portable. Verified working unchanged on Linux:

| Area | Verified |
| --- | --- |
| The whole TUI (`extended_select/`, `select.ps1`, `clean_console.ps1`) | `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')` returns the same `VirtualKeyCode` values the key map expects: `j`=74, `k`=75, ↑=38, ↓=40, Enter=13, `f`=70, `r`=82 |
| Backspace in search input | Both `0x7f` (Linux terminals) and `0x08` map to `ConsoleKey.Backspace`, so the existing check holds |
| Cyrillic input | `[Console]::ReadKey($true).KeyChar` delivers `а` (U+0430) correctly |
| Cursor control | `[Console]::SetCursorPosition`, `CursorVisible`, `$Host.UI.RawUI.BufferSize/CursorPosition` all fine |
| `HtmlAgilityPack.dll` | Loads and parses via `Add-Type -Path` |
| All HTTP + parsing (`try_request`, `html_parsers/`, `watch_*` link resolution) | Fully exercised end to end against the live site |
| JSON state (`state_management/`, `favorite_management/`, `watched_management/`) | Forward-slash paths, `Test-Path`, `New-Item -Force`, `Set-Content` — all portable |
| `Add-Type -AssemblyName 'System.Net'`, `[Console]::Beep()`, `Expand-Archive`, `Invoke-RestMethod -OutFile` | All fine |
| Path casing | Audited every `$PSScriptRoot/...` reference in the repo; all resolve on a case-sensitive filesystem |

So the work is confined to: **process launching, external binaries, and `setup.ps1`.**

---

## 2. Setup and entry point

### 2.1 `setup.ps1:7` — backslash in the generated function **BLOCKER**

`$PSScriptRoot\run.ps1` produces `/home/you/animego-console\run.ps1` on Linux. The generated `Enter-Anime` never runs.

**Fix:** use a forward slash (Windows accepts it too), and quote the path so spaces survive:

```powershell
& "$PSScriptRoot/run.ps1"
```

### 2.2 `setup.ps1:9` — `>> $PROFILE` fails when the profile directory is absent **BLOCKER**

`$PROFILE` resolves correctly on Linux (`~/.config/powershell/Microsoft.PowerShell_profile.ps1`), but that directory does not exist on a fresh install, and `>>` does not create it. Confirmed: *"Could not find a part of the path"*.

**Fix:** create the parent first.

```powershell
New-Item -Path (Split-Path $PROFILE) -ItemType Directory -Force > $null
```

### 2.3 `setup.ps1:4` — `Get-Command Enter-Anime` is the wrong idempotency check **COSMETIC**

The function only exists after the profile is reloaded, so re-running `setup.ps1` in a fresh shell appends a duplicate. Not Linux-specific, but Linux users hit it more (no installer).

**Fix:** grep the profile content instead — `if (-not (Select-String -Path $PROFILE -Pattern $functionName -Quiet))`, guarded by `Test-Path $PROFILE`.

### 2.4 `run.ps1:4` — `chcp 65001` **COSMETIC**

`chcp` is a Windows built-in for setting the console code page. On Fedora there *is* an unrelated `/usr/bin/chcp`, which errors with `chcp: too few arguments` and prints that into the console before the TUI draws. The line is redundant anyway — line 1 already sets `[Console]::OutputEncoding` to UTF-8, and Linux terminals are UTF-8 by default.

**Fix:** `if ($IsWindows) { chcp 65001 > $null }`.

---

## 3. Search — the background request process

### 3.1 `search_anime.ps1:145` — `pwsh.exe`, backslashes, and Windows quoting **BLOCKER**

This single line is why search is dead on Linux. Three separate problems:

```powershell
Start-Process -FilePath pwsh.exe -ArgumentList "-File `"`"$PSScriptRoot\helpers\request_anime_by_name.ps1`"`" ..."
```

1. `pwsh.exe` does not exist on Linux. Confirmed: *"An error occurred trying to start process 'pwsh.exe'"*.
2. `$PSScriptRoot\helpers\...` uses backslashes.
3. The doubled `""` quoting is a Windows `CreateProcess` idiom and does not survive on Linux.

**Fix:** pick the executable by platform and pass an **array** `-ArgumentList` with each path/value individually quoted. Verified working on Linux, and this form is also correct on Windows:

```powershell
$pwshExecutable = if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' }
$requestAnimeArguments = @(
    '-NoProfile'
    '-File'
    "`"$PSScriptRoot/helpers/request_anime_by_name.ps1`""
    '-inputTextFromSearchScript'
    "`"$searchInputText`""
    '-rememberMeToken'
    "`"$rememberMeToken`""
)
$requestAnimeProcess = Start-Process -FilePath $pwshExecutable -ArgumentList $requestAnimeArguments -RedirectStandardOutput $pathToSearchOutputLog -NoNewWindow -PassThru
```

Note the per-element quoting is required: a bare array element containing spaces gets **split**, so a search for `нежить и неудача` arrives at the child as just `нежить`. (Tested — this is a silent wrong-results bug, not an error.)

`Stop-Process -Force`, `-RedirectStandardOutput`, and the file-tailing loop all work on Linux as-is.

---

## 4. Playback — VLC discovery

### 4.1 `helpers/open_player.ps1:17-37` — hardcoded `C:\Program Files\...` **BLOCKER**

Both candidate paths are Windows-absolute, so on Linux `Test-Path` fails for both, and the code calls `download_vlc.ps1` (see §5.2) and then invokes `$vlcX86Path` — a path that does not exist.

**Fix:** resolve VLC through a small platform helper. On Linux `vlc` is normally in `PATH`, so `Get-Command` is the natural lookup:

```powershell
function Get-VlcPath {
    if (-not $IsWindows) {
        return (Get-Command vlc -ErrorAction SilentlyContinue)?.Source
    }

    foreach ($candidate in @('C:\Program Files\VideoLAN\VLC\vlc.exe', 'C:\Program Files (x86)\VideoLAN\VLC\vlc.exe')) {
        if (Test-Path $candidate) { return $candidate }
    }

    return $null
}
```

The `& $vlc --http-referrer ... --fullscreen` invocation itself is identical on Linux — only discovery changes. On Linux, when VLC is missing, print an install hint (`sudo dnf install vlc` / `sudo apt install vlc`) rather than attempting a download.

### 4.2 `select_anime_from_downloaded_folder.ps1:129` — second hardcoded VLC path **BLOCKER**

Same literal, duplicated. Local playback of downloaded episodes cannot work on Linux.

**Fix:** use the same helper from §4.1 instead of the inline literal.

---

## 5. External tool bootstrap

### 5.1 `download_ffmpeg.ps1:18` — meaningless `PATH` rebuild **COSMETIC**

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
```

`Machine` and `User` environment scopes are Windows-registry concepts; on Linux both return `$null`, so this assigns the literal string `";"`.

**This is harmless, contrary to what it looks like.** PowerShell's environment provider is case-sensitive on Linux, so `$env:Path` and `$env:PATH` are *different variables* — the assignment creates a junk `Path` and leaves the real `PATH` untouched. Verified: after running the line, `$env:PATH` is still intact and `ffmpeg` both resolves via `Get-Command` and executes. (On Windows the provider is case-insensitive, which is exactly why the line works as intended there.)

So this is a correctness/clarity fix, not a bug fix. It still deserves the guard: the line sits *outside* the `try/catch` and runs on every dot-source — including from `open_player.ps1` on each ffplay playback — doing nothing but writing a stray variable that gets inherited by child processes.

**Fix:** guard it — the line only has meaning on Windows, where it exists to pick up a `PATH` that `winget` just changed.

```powershell
if ($IsWindows) {
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
}
```

### 5.2 `download_ffmpeg.ps1:5-11` and `download_vlc.ps1:1-8` — elevation and `winget` **BLOCKER**

Three Windows-only APIs in each:

- `[Security.Principal.WindowsIdentity]::GetCurrent()` — throws *"Windows Principal functionality is not supported on this platform."*
- `Start-Process -Verb RunAs` — throws *"The parameter '-Verb' is not supported ... on this edition of PowerShell."*
- `winget` — does not exist on Linux.

**Fix:** on Linux, do not attempt to install anything automatically. Package managers differ per distro and require `sudo`, which should not be invoked behind the user's back from a TUI. Detect and instruct instead:

```powershell
if (-not $IsWindows) {
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Host 'ffmpeg is required. Install it with your package manager, e.g.:'
        Write-Host '   sudo dnf install ffmpeg      # Fedora'
        Write-Host '   sudo apt install ffmpeg      # Debian/Ubuntu'
    }
    return
}
```

Note `Start-Process -Verb RunAs` has no portable equivalent — re-running under `sudo` is the closest analogue, and deliberately not doing so is the right call here.

### 5.3 `download_vlc.ps1:8` — installs the wrong package **BUG (platform-independent)**

The "VLC not installed" branch runs `winget install --id=Gyan.FFmpeg -e`, which installs FFmpeg, not VLC. So VLC auto-install has never worked on Windows either. Worth fixing while touching this file: `winget install --id=VideoLAN.VLC -e`.

### 5.4 `download_unzip_upscaler.ps1:9` — Windows-only upscaler build **BLOCKER**

Hardcodes `video2x-windows-amd64.zip`. Checked the upstream releases: 6.4.0 ships **`Video2X-x86_64.AppImage`** for Linux (6.2.0–6.3.1 additionally shipped `.deb`).

**Fix:** select the asset by platform. The AppImage is a single file, so on Linux skip `Expand-Archive` entirely — download it directly and mark it executable:

```powershell
if ($IsWindows) {
    # existing zip download + Expand-Archive
} else {
    Invoke-RestMethod 'https://github.com/k4yt3x/video2x/releases/download/6.4.0/Video2X-x86_64.AppImage' -OutFile $appImagePath
    chmod +x $appImagePath
}
```

AppImages need FUSE; if unavailable, `--appimage-extract` is the fallback. A distro package or the `.deb` is a reasonable alternative.

### 5.5 `upscale_video.ps1:12` — `video2x.exe` **BLOCKER**

Hardcodes the `.exe` name.

**Fix:** derive from platform, matching whatever §5.4 downloaded:

```powershell
$upscalerExePath = if ($IsWindows) { "$PSScriptRoot/../../temp/upscaler/video2x.exe" } else { "$PSScriptRoot/../../temp/upscaler/Video2X-x86_64.AppImage" }
```

The rest of the script (`Start-Process -NoNewWindow -RedirectStandardOutput`, the log-tailing loop, `Move-Item`) is portable. Its `-ArgumentList` is a single string, which works on both platforms as long as the paths inside stay quoted — they already are.

---

## 6. Things that look Windows-specific but are fine

Called out so they don't get "fixed" unnecessarily:

- **`download_from_m3u8.ps1:10-19` filename substitution table.** It escapes `\ : ? " < > |`, which are only illegal on Windows — on Linux just `/` and NUL are. Escaping more than necessary is harmless, the reverse table in `select_anime_from_downloaded_folder.ps1:1-10` is symmetric, and keeping it identical means a `temp/animes` tree stays readable on both platforms. **Leave it alone.**
- **`[Console]::Beep()`** (`download_from_m3u8.ps1:51`) — does not throw on Linux.
- **`clean_console.ps1`** — already wraps `SetCursorPosition` in `try/catch`; the cursor maths behaves the same.
- **Line endings** — `.gitattributes` only marks `*.png binary`. PowerShell reads CRLF and LF equally, so no `text=auto` change is needed for the scripts to run.

---

## 7. Suggested order of work

1. **`setup.ps1`** (§2.1, §2.2) — without it there is no entry point.
2. **`search_anime.ps1:145`** (§3.1) — restores search, the main feature.
3. **Add the platform helpers** (VLC path, `pwsh`/`pwsh.exe` name), then use them from `open_player.ps1` and `select_anime_from_downloaded_folder.ps1` (§4.1, §4.2) — restores playback.
4. **`download_vlc.ps1` / `download_ffmpeg.ps1` install branches** (§5.2, §5.3) — turn auto-install into install hints.
5. **Upscaler** (§5.4, §5.5) — the most optional feature, and the heaviest dependency.
6. **`download_ffmpeg.ps1:18` guard and `chcp`** (§5.1, §2.4) — tidy-ups, no behaviour depends on them.

Steps 1–3 are enough for a fully usable Linux client with system-installed VLC and ffmpeg.

---

## 8. Implementation status

All of the above is implemented. The shared helpers landed as three scripts under `helpers/platform_management/` (`get_pwsh_executable.ps1`, `get_vlc_path.ps1`, `get_upscaler_path.ps1`) rather than one `platform.ps1` with functions, to match the repo's existing "helper script returns a value" idiom.
