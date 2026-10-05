$ErrorActionPreference = 'Stop'
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsRoot = & $vswhere -latest -products '*' -property installationPath
if (-not $vsRoot) { throw 'Visual Studio Build Tools required for native SDK host' }
$msvc = Get-ChildItem -LiteralPath (Join-Path $vsRoot 'VC\Tools\MSVC') -Directory | Sort-Object Name -Descending | Select-Object -First 1
$kitRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10'
$kit = Get-ChildItem -LiteralPath (Join-Path $kitRoot 'Include') -Directory | Sort-Object Name -Descending | Select-Object -First 1
$compiler = Join-Path $msvc.FullName 'bin\Hostx64\x86\cl.exe'
$outDir = Join-Path $PSScriptRoot 'editor_lab'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$arguments = @('/nologo', '/O2', '/MT', '/D_CRT_SECURE_NO_WARNINGS',
    ('/I' + (Join-Path $msvc.FullName 'include')),
    ('/I' + (Join-Path $kit.FullName 'ucrt')),
    ('/I' + (Join-Path $kit.FullName 'shared')),
    ('/I' + (Join-Path $kit.FullName 'um')),
    ('/Fo' + (Join-Path $outDir 'UCEditorHost.obj')),
    ('/Fe' + (Join-Path $outDir 'UCEditorHost.exe')),
    (Join-Path $PSScriptRoot 'editor_src\UCEditorSdkHost.cpp'), '/link',
    ('/LIBPATH:' + (Join-Path $msvc.FullName 'lib\x86')),
    ('/LIBPATH:' + (Join-Path $kitRoot ('Lib\' + $kit.Name + '\ucrt\x86'))),
    ('/LIBPATH:' + (Join-Path $kitRoot ('Lib\' + $kit.Name + '\um\x86'))), 'kernel32.lib')
$arguments = @('/EHsc', '/Zc:forScope-', '/D_UNICODE', '/DUNICODE', '/Zc:wchar_t-', '/DWIN32_LEAN_AND_MEAN',
        ('/I' + (Join-Path $outDir 'headers\Core\Inc')),
        ('/I' + (Join-Path $outDir 'headers\Engine\Inc')),
        ('/I' + (Join-Path $outDir 'headers\Editor\Inc')),
        ('/I' + (Join-Path $outDir 'headers\Window\Inc'))) +
        $arguments +
        @((Join-Path $outDir 'Core.lib'), (Join-Path $outDir 'Engine.lib'), (Join-Path $outDir 'Editor.lib'), (Join-Path $outDir 'Window.lib'))
& $compiler @arguments
if ($LASTEXITCODE -ne 0) { throw 'Native host compilation failed' }
$hashes = @{}
foreach ($name in @('Core.dll', 'Engine.dll', 'Editor.dll', 'Window.dll')) {
    $hashes[$name] = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot ('..\..\DevInstall\System\' + $name)) -Algorithm SHA256).Hash.ToLowerInvariant()
}
$record = @{
    host_sha256 = (Get-FileHash -LiteralPath (Join-Path $outDir 'UCEditorHost.exe') -Algorithm SHA256).Hash.ToLowerInvariant()
    source_sha256 = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'editor_src\UCEditorSdkHost.cpp') -Algorithm SHA256).Hash.ToLowerInvariant()
    dll_sha256 = $hashes
}
$record | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $outDir 'host-build.json') -Encoding UTF8
