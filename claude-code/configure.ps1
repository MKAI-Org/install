param(
  [string]$ApiKey,
  [string]$BaseUrl = ''
)

if (-not $ApiKey) { $ApiKey = Read-Host 'ApiKey' }
if (-not $PSBoundParameters.ContainsKey('BaseUrl')) {
  $BaseUrl = Read-Host 'BaseUrl（没有直接回车）'
}
if (-not $ApiKey) { throw 'ApiKey 必填' }

$dir = Join-Path $env:USERPROFILE '.claude'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
if ($BaseUrl) {
  @"
{
  "env": {
    "ANTHROPIC_API_KEY": "$ApiKey",
    "ANTHROPIC_BASE_URL": "$BaseUrl"
  }
}
"@ | Set-Content -Encoding UTF8 (Join-Path $dir 'settings.json')
} else {
  @"
{
  "env": {
    "ANTHROPIC_API_KEY": "$ApiKey"
  }
}
"@ | Set-Content -Encoding UTF8 (Join-Path $dir 'settings.json')
}
Write-Host "==> 已写 $dir\settings.json"

[Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', $ApiKey, 'User')
$env:ANTHROPIC_API_KEY = $ApiKey
if ($BaseUrl) {
  [Environment]::SetEnvironmentVariable('ANTHROPIC_BASE_URL', $BaseUrl, 'User')
  $env:ANTHROPIC_BASE_URL = $BaseUrl
}
Write-Host "==> 已设置用户环境变量（不打印 key）。新开 PowerShell 后 claude"
