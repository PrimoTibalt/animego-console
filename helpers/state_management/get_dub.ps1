$json = Get-Content "$PSScriptRoot/../../temp/state.json" | ConvertFrom-Json
return $json.dub