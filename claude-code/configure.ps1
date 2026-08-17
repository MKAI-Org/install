param(
  [string]$ApiKey,
  [string]$BaseUrl = ''
)

if (-not $ApiKey) { $ApiKey = Read-Host 'ApiKey' }
if (-not $PSBoundParameters.ContainsKey('BaseUrl')) {
  $BaseUrl = Read-Host 'BaseUrl (empty=skip)'
}
if (-not $ApiKey) { throw 'ApiKey required' }

$dir = Join-Path $env:USERPROFILE '.claude'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$jsonPath = Join-Path $dir 'settings.json'
if ($BaseUrl) {
  $text = @"
{
  "env": {
    "ANTHROPIC_API_KEY": "$ApiKey",
    "ANTHROPIC_BASE_URL": "$BaseUrl"
  }
}
"@
} else {
  $text = @"
{
  "env": {
    "ANTHROPIC_API_KEY": "$ApiKey"
  }
}
"@
}
$enc = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText($jsonPath, $text, $enc)
Write-Host "==> wrote $jsonPath"

[Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', $ApiKey, 'User')
$env:ANTHROPIC_API_KEY = $ApiKey
if ($BaseUrl) {
  [Environment]::SetEnvironmentVariable('ANTHROPIC_BASE_URL', $BaseUrl, 'User')
  $env:ANTHROPIC_BASE_URL = $BaseUrl
}
Write-Host '==> user env set (key not printed). open a new PowerShell then run claude'
