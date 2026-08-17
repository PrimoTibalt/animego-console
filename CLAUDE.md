# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A console application (pure PowerShell 7, dot-sourced `.ps1` scripts — no build system, no test suite, no package manager) for browsing and watching anime from animego.one in the terminal. It scrapes HTML/JSON from the site, extracts player links from four possible embedded players (Kodik, Sibnet, CVN, AniBoom), and hands the resulting stream URL to VLC or ffplay. It also tracks watch progress and a favorites list as local JSON files, and can download episodes or upscale them with video2x.

Windows/PowerShell-7-only: it shells out to `vlc.exe` at hardcoded `C:\Program Files\...` paths, uses `pwsh.exe` as a subprocess, and downloads Windows binaries for ffmpeg/VLC/video2x on demand. There is no Linux/macOS support path.

## Running it

There is no build or test command — this is an interpreted script tree run directly by PowerShell 7 (`pwsh`).

- Install/register the CLI: `./setup.ps1` (appends an `Enter-Anime` function to the user's `$PROFILE`, then requires a new terminal session)
- Run the app: `Enter-Anime` (after setup), or directly `./run.ps1`
- There are no automated tests, linter, or CI config in this repo.

## Architecture

### Execution model: dot-sourcing, not modules

Scripts do not import each other via modules — everything is chained with dot-sourcing (`. "$PSScriptRoot/..."`) so callees share the caller's scope. `run.ps1` defines the shared `SelectParameters` class and loads `HtmlAgilityPack.dll` once at the top; everything downstream depends on that class already being defined. Keep this in mind when tracing behavior: a helper's effect on `$script:`-scoped variables can leak into the caller.

### Top-level flow

`run.ps1` shows the main menu (Search / Choose from watched / Choose from favorites / Choose from downloaded) via `helpers/select.ps1`, and manages saved login credentials (`temp/creds.txt`). Each menu entry dot-sources a top-level `select_*`/`search_*` script, which funnel into a common pipeline:

```
search_anime.ps1 / select_anime_from_*.ps1
        -> select_episode.ps1        (list episodes, or skip straight to dubs if it's a movie)
        -> select_dubbing.ps1        (list dub/translation options, then players)
        -> watch_kodik.ps1 / watch_sibnet.ps1 / watch_cvn.ps1 / watch_aniboom.ps1
        -> helpers/open_player.ps1   (launches VLC or ffplay, or downloads instead)
```

`select_dubbing.ps1` dispatches to the right `watch_*.ps1` based on a substring match on the player URL (`kodik`, `sibnet`, `cdn-iframe` → CVN, else AniBoom). Each `watch_*.ps1` implements that player's own link-extraction/decoding scheme (e.g. `watch_kodik.ps1` reimplements the ROT-N + base64 decoding scheme from the Python `anime_parsers_ru` library — see the comment there) and ultimately calls `helpers/open_player.ps1` with the resolved stream URL.

### `helpers/` subsystems

- `html_parsers/` — HtmlAgilityPack-based scraping of animego.one search results, episode lists, translation/dub lists, and CDN player responses. `HtmlAgilityPack.dll` is a vendored binary dependency loaded via `Add-Type -Path`.
- `state_management/` — the *current* in-progress selection (`temp/state.json`): anime name/href/episode/dub. Read/written as the user drills into episode → dub selection.
- `watched_management/` — syncs `state.json` into the persistent `temp/global.json` (per-anime watch history/progress) when an episode is actually watched. `global.json` and `favorites.json` are the two files a user would copy to sync progress across machines (see README).
- `favorite_management/` — `temp/favorites.json` CRUD; favorites are shown with a `★` prefix wherever anime names are listed.
- `login_management/` — optional animego.one login flow; stores credentials in `temp/creds.txt` (plaintext — see README's explicit warning to use a throwaway account) and derives a `REMEMBERME` cookie used so search can find login-gated titles.
- `download_management/` — on-demand downloaders for external tools (ffmpeg, VLC, video2x) and for saving an episode locally via `download_from_m3u8.ps1`.
- `upscaling_management/` — drives video2x over previously-downloaded episodes.
- `extended_select/` — the custom TUI widget. `base_select.ps1` is a single-page arrow-key/vim-key (`j`/`k`/`h`/`l`) list selector built on raw `[Console]`/`$Host.UI.RawUI` calls, with hookable `actionOnF`/`actionOnR`/`actionOnEachKey` callbacks (used throughout the app for favorite-toggling, download-triggering, etc. — see `select_dubbing.ps1`'s `actionOnF` for the download-on-`f` pattern). `multipage_extension.ps1` wraps it to paginate when a list won't fit the console buffer, and is the entry point every caller should use (via `helpers/select.ps1`).
- `request_anime_by_name.ps1` / `try_request.ps1` — networking core. `try_request.ps1` round-robins across animego's several mirror domains (`animego.me/.club/.org/.one/.la`) with a short timeout, since the primary domain changes/gets blocked periodically. Search itself runs as a **background `pwsh.exe` subprocess** (spawned from `search_anime.ps1`, restarted on every keystroke past 3 chars) that streams results to a temp log file, which the foreground script tails non-blockingly — this is what makes search "non-blocking" while the user keeps typing.

### Data files (all under `temp/`, gitignored)

- `state.json` — current selection in progress (name, href, episode, dub)
- `global.json` — per-anime watch history/progress, keyed by anime name, values are JSON-encoded state blobs (see `watched_management/append_watched.ps1` for the merge logic — it's intentionally tightly coupled to `state.json`'s shape)
- `favorites.json` — favorited anime
- `creds.txt` / `rememberme.txt` — login credentials / derived cookie token
- `search_log.txt`, `try_request_log.html` — scratch logs from the background search process and failed requests
- `animes/` — downloaded episodes, scanned by `select_anime_from_downloaded_folder.ps1`

### Site coupling

Nearly everything here is reverse-engineered against animego.me's current HTML/JS and each embedded player's current API — there is no stable public API. Expect scraping logic (`html_parsers/`, the per-player `watch_*.ps1` decoders) to be the most fragile part of the codebase and the most likely place a "bug" report traces back to an upstream site change rather than a logic error.

The site is a Hotwire Turbo / Stimulus app. Every endpoint below needs `x-requested-with: XMLHttpRequest` (or `Accept: application/json`) and answers `{status, data: {content: "<html>"}}` — plain requests get a 404 or a full page instead. `try_request.ps1` unwraps `data.content`.

| Step | Request | Markup the parser keys off |
| --- | --- | --- |
| search | `GET /search/all?q=<urlencoded>&navbar=true` | `a.ajax-search__item` + `.ajax-search__item-title`, scoped to the section whose header links to `/search/anime` |
| episodes | `GET /player/{animeId}` | `[data-episode]` (id) + `[data-episode-number]` (label) |
| dubs + players | `GET /player/videos/{episodeId}` | `[data-player]` (url) + `[data-translation-title]` + `[data-provider-title]` |
| login | `POST /login` with `_csrf_token`/`_username`/`_password`/`_remember_me` | `REMEMBERME` cookie off the 302 |

`{animeId}` is the numeric suffix of an `/anime/<slug>-<id>` href. Movies have no `[data-episode]` nodes — their providers are inline in the `/player/{animeId}` response, which is why `select_episode.ps1` falls through to `select_dubbing.ps1` with the same HTML.

Two traps worth knowing: the search response's "Люди" (people) section also uses `/anime/...` hrefs, so filtering by href prefix alone pulls in non-anime results; and `/player/{animeId}` returns roughly a megabyte for long-running shows, so request timeouts have to be generous.

Provider notes: Kodik obfuscates its stream URL as ROT-18 over latin letters then base64 (the shift lives in kodikplayer.com's `app.player_single` bundle; `watch_kodik.ps1` seeds 18 and brute-forces 0..25 as a fallback, recognising success by the `mp4:hls:manifest` marker), and its `/ftor` response nests each quality's source in an array. CVH URLs encode the episode as `/cdn-iframe/{titleId}/{dub}/{season}/{episode}` for serials and `/cdn-iframe/{titleId}/{dub}` for movies, and its plapi `sources` now only populates `hlsUrl`/`dashUrl` plus the low-quality `mpeg*` fields.
