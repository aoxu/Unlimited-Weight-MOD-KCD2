param([string]$PythonPath)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$source = Join-Path $PSScriptRoot 'src/UnlimitedWeight'
$output = Join-Path $PSScriptRoot 'dist/UnlimitedWeight'
$dataOutput = Join-Path $output 'Data'
[void][System.IO.Directory]::CreateDirectory($dataOutput)
Copy-Item -LiteralPath (Join-Path $source 'mod.manifest') -Destination (Join-Path $output 'mod.manifest')

# ZIP stored entries, forward-slash paths, no enclosing Data directory.
$pakPath = Join-Path $dataOutput 'unlimitedweight.pak'
$stream = [System.IO.File]::Open($pakPath, [System.IO.FileMode]::Create)
$archive = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $dataSource = Join-Path $source 'Data'
    foreach ($file in Get-ChildItem -LiteralPath $dataSource -Recurse -File) {
        $relative = $file.FullName.Substring($dataSource.Length + 1).Replace('\', '/')
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $relative, [System.IO.Compression.CompressionLevel]::NoCompression)
    }
} finally {
    $archive.Dispose()
    $stream.Dispose()
}

# Read back and validate the generated package before distribution.
$archive = [System.IO.Compression.ZipFile]::OpenRead($pakPath)
try {
    $expected = 'Libs/Tables/rpg/rpg_param__unlimitedweight.xml'
    if ($archive.Entries.Count -ne 1 -or $archive.Entries[0].FullName -cne $expected) { throw 'Unexpected PAK structure.' }
    $reader = [System.IO.StreamReader]::new($archive.Entries[0].Open())
    try { [xml]$patch = $reader.ReadToEnd() } finally { $reader.Dispose() }
    $rows = @($patch.database.rpg_params.rpg_param)
    if ($rows.Count -ne 2 -or $rows[0].rpg_param_key -ne 'BaseInventoryCapacity' -or $rows[1].rpg_param_key -ne 'MaxBaseInventoryCapacity' -or @($rows | Where-Object { $_.rpg_param_value -ne '999999' }).Count) { throw 'Unexpected RPG patch.' }
} finally { $archive.Dispose() }
[xml]$manifest = Get-Content -LiteralPath (Join-Path $output 'mod.manifest') -Raw
if ($manifest.kcd_mod.info.modid -ne 'unlimitedweight') { throw 'Unexpected mod ID.' }

$zipPath = Join-Path $PSScriptRoot 'dist/UnlimitedWeight-1.0.1.zip'
$stream = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::Create)
$archive = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($relative in @('mod.manifest', 'Data/unlimitedweight.pak')) {
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, (Join-Path $output $relative), ('UnlimitedWeight/' + $relative), [System.IO.Compression.CompressionLevel]::NoCompression)
    }
} finally {
    $archive.Dispose()
    $stream.Dispose()
}
if (-not $PythonPath) {
    $command = Get-Command python -ErrorAction SilentlyContinue
    if ($command) { $PythonPath = $command.Source }
    else { $PythonPath = Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' }
}
if (-not (Test-Path -LiteralPath $PythonPath)) { throw 'Python 3 required; pass -PythonPath with python.exe path.' }
& $PythonPath (Join-Path $PSScriptRoot 'store_archives.py') $zipPath
if ($LASTEXITCODE -ne 0) { throw 'Stored ZIP conversion or validation failed.' }
Write-Output "Built and structurally verified: $zipPath"
