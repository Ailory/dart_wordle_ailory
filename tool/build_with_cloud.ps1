[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('windows', 'apk')]
  [string]$Target,
  [Parameter(Mandatory)]
  [ValidatePattern('^https://')]
  [string]$ProxyEndpoint,
  [string]$FlutterRoot = 'C:\Users\AiloryInk\Downloads\flutter_windows_3.47.5-stable\flutter'
)

$dart = Join-Path $FlutterRoot 'bin\cache\dart-sdk\bin\dart.exe'
$flutterPackages = Join-Path $FlutterRoot 'packages\flutter_tools\.dart_tool\package_config.json'
$flutterSnapshot = Join-Path $FlutterRoot 'bin\cache\flutter_tools.snapshot'
$gitPath = Join-Path $FlutterRoot 'bin\mingit\cmd'

if (-not (Test-Path -LiteralPath $dart)) {
  throw "Dart was not found at $dart"
}

$env:Path += ";$gitPath"
$normalizedEndpoint = $ProxyEndpoint.TrimEnd('/')
$arguments = @(
  "--packages=$flutterPackages",
  $flutterSnapshot,
  'build',
  $Target,
  '--release',
  "--dart-define=GROQ_PROXY_ENDPOINT=$normalizedEndpoint"
)

& $dart @arguments
exit $LASTEXITCODE
