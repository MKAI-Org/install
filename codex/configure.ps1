# Configure Codex API key. Does not install.
param(
  [string]$ApiKey,
  [string]$BaseUrl,
  [string]$Model,
  [string]$WireApi = 'chat',
  [string]$Provider = 'custom'
)

if (-not $ApiKey) { $ApiKey = Read-Host 'ApiKey' }
if (-not $BaseUrl) { $BaseUrl = Read-Host 'BaseUrl' }
if (-not $Model) { $Model = Read-Host 'Model' }
if (-not $ApiKey -or -not $BaseUrl -or -not $Model) { throw 'ApiKey / BaseUrl / Model 都要填' }

$codexHome = Join-Path $env:USERPROFILE '.codex'
New-Item -ItemType Directory -Force -Path $codexHome | Out-Null
$cfg = Join-Path $codexHome 'config.toml'
$text = @"
model = "$Model"
model_provider = "$Provider"

[model_providers.$Provider]
name = "$Provider"
base_url = "$BaseUrl"
env_key = "OPENAI_API_KEY"
wire_api = "$WireApi"
"@
$enc = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText($cfg, $text, $enc)
Write-Host "==> wrote $cfg"

[Environment]::SetEnvironmentVariable('OPENAI_API_KEY', $ApiKey, 'User')
$env:OPENAI_API_KEY = $ApiKey
Write-Host "==> 已设置用户环境变量 OPENAI_API_KEY（不打印）。新开 PowerShell 后 codex"
