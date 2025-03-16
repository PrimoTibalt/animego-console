$json = Get-Content ./temp/state.json | ConvertFrom-Json
return $json.episode
