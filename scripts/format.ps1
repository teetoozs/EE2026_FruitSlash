param([string]$FormatterPath = 'verible-verilog-format')

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$formatConfig = Join-Path $repoRoot '.verible-format'
$sources = Get-ChildItem (Join-Path $repoRoot 'rtl'), (Join-Path $repoRoot 'sim') -Recurse -Filter '*.v'

foreach ($source in $sources) {
    & $FormatterPath "--flagfile=$formatConfig" --inplace $source.FullName
    if ($LASTEXITCODE -ne 0) {
        throw "Formatting failed: $($source.FullName)"
    }
}
