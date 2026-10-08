[CmdletBinding()]
param(
  [string]$CloudflareRoot = (Join-Path $PSScriptRoot '..\cloudflare')
)

$npx = 'C:\Program Files\nodejs\npx.cmd'
if (-not (Test-Path -LiteralPath $npx)) {
  throw "npx was not found at $npx"
}

Set-Location $CloudflareRoot
Write-Host 'Enter a newly generated Groq key. The input is hidden.'
& $npx --yes wrangler secret put GROQ_API_KEY
if ($LASTEXITCODE -ne 0) {
  throw 'Cloudflare did not save the Groq secret.'
}

Write-Host 'The Groq secret was saved in Cloudflare.'
Read-Host 'Press Enter to close this window' | Out-Null
