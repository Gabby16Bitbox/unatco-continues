# Call the bridge with its isolated Python dependencies, from any working directory.
$bridgePython = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $bridgePython)) {
    throw 'Private Python environment is missing. See tools/editor_bridge/README.md.'
}
& $bridgePython (Join-Path $PSScriptRoot 'cli.py') @args
exit $LASTEXITCODE
