[CmdletBinding()]
param(
  [switch]$SaveKey,
  [string]$FlutterRoot = 'C:\Users\AiloryInk\Downloads\flutter_windows_3.47.5-stable\flutter'
)

$previousProcessApiKey = $env:GROQ_API_KEY
$apiKey = $null
if (-not $SaveKey) {
  $apiKey = $env:GROQ_API_KEY
  if ([string]::IsNullOrWhiteSpace($apiKey)) {
    $apiKey = [Environment]::GetEnvironmentVariable('GROQ_API_KEY', 'User')
  }
}

$pointer = [IntPtr]::Zero
if ([string]::IsNullOrWhiteSpace($apiKey)) {
  $secureApiKey = Read-Host -Prompt 'Enter a new Groq API key' -AsSecureString
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureApiKey)
  $apiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
}

try {
  if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw 'A Groq API key is required.'
  }

  if ($SaveKey) {
    [Environment]::SetEnvironmentVariable('GROQ_API_KEY', $apiKey, 'User')
    Write-Output 'The Groq API key was saved for the current Windows user.'
  }

  $env:GROQ_API_KEY = $apiKey

  $dart = Join-Path $FlutterRoot 'bin\cache\dart-sdk\bin\dart.exe'
  if (-not (Test-Path -LiteralPath $dart)) {
    throw "Dart was not found at $dart"
  }

  & $dart run tool/groq_proxy.dart
  exit $LASTEXITCODE
}
finally {
  if ($null -eq $previousProcessApiKey) {
    Remove-Item Env:\GROQ_API_KEY -ErrorAction SilentlyContinue
  }
  else {
    $env:GROQ_API_KEY = $previousProcessApiKey
  }

  if ($pointer -ne [IntPtr]::Zero) {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
  }
}
