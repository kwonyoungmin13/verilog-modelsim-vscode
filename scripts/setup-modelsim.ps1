[CmdletBinding()]
param(
    [string]$BinPath,
    [string]$BuildRoot,
    [switch]$SkipExtension,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot

function Find-VSCodeCli {
    foreach ($name in @('code.cmd', 'code.exe', 'code')) {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) { return $command.Source }
    }
    $candidates = @()
    if ($env:LOCALAPPDATA) {
        $candidates += Join-Path $env:LOCALAPPDATA 'Programs/Microsoft VS Code/bin/code.cmd'
    }
    foreach ($programRoot in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($programRoot) { $candidates += Join-Path $programRoot 'Microsoft VS Code/bin/code.cmd' }
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}

try {
    . (Join-Path $PSScriptRoot 'modelsim-common.ps1')
    $config = Get-ModelSimConfiguration -Workspace $workspace
    $configuredBin = $config.binPath
    if ($PSBoundParameters.ContainsKey('BinPath')) { $configuredBin = $BinPath }
    $resolvedBin = Resolve-ModelSimBin -ConfiguredPath $configuredBin -Workspace $workspace
    Write-Host "ModelSim tools found: $resolvedBin"
    Write-Host 'Verified: vlib.exe, vmap.exe, vlog.exe, vsim.exe'

    if ($CheckOnly) {
        Write-Host 'CHECK OK. No files, settings, or extensions were changed.'
        exit 0
    }

    $configuredBuildRoot = $config.buildRoot
    if ($PSBoundParameters.ContainsKey('BuildRoot')) { $configuredBuildRoot = $BuildRoot }
    $resolvedBuildRoot = Resolve-ModelSimBuildRoot -ConfiguredPath $configuredBuildRoot -Workspace $workspace
    New-Item -ItemType Directory -Path $resolvedBuildRoot -Force | Out-Null
    $probePath = Join-Path $resolvedBuildRoot ('.write-check-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [IO.File]::WriteAllText($probePath, 'ModelSim setup write check')
    } catch {
        throw "Cannot write to buildRoot '$resolvedBuildRoot'. Run setup with -BuildRoot pointing to a writable ASCII directory. $($_.Exception.Message)"
    } finally {
        if (Test-Path -LiteralPath $probePath -PathType Leaf) { Remove-Item -LiteralPath $probePath -Force }
    }

    $localPath = Join-Path $workspace 'modelsim.local.json'
    $localConfig = [ordered]@{}
    if (Test-Path -LiteralPath $localPath -PathType Leaf) {
        $existingLocal = Get-Content -LiteralPath $localPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($existingLocal -isnot [pscustomobject]) { throw 'modelsim.local.json must contain a JSON object.' }
        foreach ($property in $existingLocal.PSObject.Properties) {
            $localConfig[$property.Name] = $property.Value
        }
    }
    $localConfig['binPath'] = $resolvedBin
    $localConfig['buildRoot'] = $resolvedBuildRoot
    $localConfig | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $localPath -Encoding UTF8
    Write-Host "Local settings saved: $localPath"
    Write-Host "Build directory: $resolvedBuildRoot"

    if (-not $SkipExtension) {
        $codeCli = Find-VSCodeCli
        if (-not $codeCli) {
            Write-Warning 'VS Code CLI was not found. In VS Code, open Extensions (Ctrl+Shift+X), search for mshr-h.veriloghdl, and install it manually.'
        } else {
            try {
                $installedExtensions = @(& $codeCli --list-extensions 2>&1)
                $listExit = $LASTEXITCODE
                if ($listExit -eq 0 -and $installedExtensions -contains 'mshr-h.veriloghdl') {
                    Write-Host 'VS Code extension is already installed: mshr-h.veriloghdl'
                } else {
                    & $codeCli --install-extension mshr-h.veriloghdl
                    if ($LASTEXITCODE -ne 0) { throw "VS Code CLI returned exit $LASTEXITCODE." }
                    Write-Host 'VS Code extension installed: mshr-h.veriloghdl'
                }
            } catch {
                Write-Warning "ModelSim settings are ready, but the VS Code extension could not be installed. Open Extensions (Ctrl+Shift+X), search for mshr-h.veriloghdl, and install it manually. $($_.Exception.Message)"
            }
        }
    }

    Write-Host 'SETUP OK. Open examples/mux4to1/mux4to1.v in VS Code, then press Ctrl+Shift+B.'
    exit 0
} catch {
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    Write-Host 'If ModelSim is installed elsewhere, run setup with -BinPath pointing to the folder containing vsim.exe.'
    exit 1
}
