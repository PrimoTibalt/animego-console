$stateContent = Get-Content "$PSScriptRoot/../../temp/state.json" -Raw
. "$PSScriptRoot/append_watched.ps1" $stateContent