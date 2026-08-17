# Configure Codex API key. Does not install.
param(
  [Parameter(Mandatory = $true)][string]$ApiKey,
  [Parameter(Mandatory = $true)][string]$BaseUrl,
  [Parameter(Mandatory = $true)][string]$Model,
  [string]$WireApi = 'chat',
  [string]$Provider = 'custom'
)

$codexHome = Join-Path $env:USERPROFILE '.codex'
New-Item -ItemType Directory -Force -Path $codexHome | Out-Null
$cfg = Join-Path $codexHome 'config.toml'
@"
model = "$Model"
model_provider = "$Provider"

[model_providers.$Provider]
name = "$Provider"
base_url = "$BaseUrl"
env_key = "OPENAI_API_KEY"
wire_api = "$WireApi"
"@ | Set-Content -Encoding UTF8 $cfg
Write-Host "==> 已写 $cfg"

[Environment]::SetEnvironmentVariable('OPENAI_API_KEY', $ApiKey, 'User')
$env:OPENAI_API_KEY = $ApiKey
Write-Host "==> 已设置用户环境变量 OPENAI_API_KEY（不打印）。新开 PowerShell 后 codex"
