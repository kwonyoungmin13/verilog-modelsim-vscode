# Shared discovery/configuration helpers for Windows PowerShell 5.1.
# These functions do not create directories or start ModelSim.

function Get-ModelSimConfiguration {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Workspace)

    $settings = [ordered]@{
        binPath = ''
        runTime = '1 us'
        top = ''
        buildRoot = ''
    }
    foreach ($name in @('modelsim.json', 'modelsim.local.json')) {
        $path = Join-Path $Workspace $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        try {
            $parsed = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        } catch {
            throw "Cannot read ${name}: $($_.Exception.Message)"
        }
        if ($null -eq $parsed -or $parsed -isnot [pscustomobject]) {
            throw "$name must contain a JSON object."
        }
        foreach ($key in @('binPath', 'runTime', 'top', 'buildRoot')) {
            $property = $parsed.PSObject.Properties[$key]
            if ($null -eq $property) { continue }
            if ($null -ne $property.Value -and $property.Value -isnot [string]) {
                throw "$name setting '$key' must be a string."
            }
            $settings[$key] = [string]$property.Value
        }
    }
    [pscustomobject]$settings
}

function ConvertTo-ModelSimFullPath {
    param([Parameter(Mandatory = $true)][string]$Path, [string]$Workspace)

    $expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"'))
    if (-not [IO.Path]::IsPathRooted($expanded)) {
        $expanded = Join-Path $Workspace $expanded
    }
    [IO.Path]::GetFullPath($expanded)
}

function Find-ModelSimBinAtPath {
    param([string]$Path)

    if (-not $Path) { return }
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        if ([IO.Path]::GetExtension($Path) -ne '.exe') { return }
        $Path = Split-Path -Parent $Path
    }
    # Accept either the executable directory or an installation root.
    foreach ($child in @('', 'win64', 'win32aloem', 'win64aloem', 'win32', 'bin', 'windows/bin')) {
        $candidate = $Path
        if ($child) { $candidate = [IO.Path]::Combine($Path, $child) }
        $complete = $true
        foreach ($tool in @('vlib.exe', 'vmap.exe', 'vlog.exe', 'vsim.exe')) {
            if (-not (Test-Path -LiteralPath ([IO.Path]::Combine($candidate, $tool)) -PathType Leaf)) {
                $complete = $false
                break
            }
        }
        if ($complete) { return [IO.Path]::GetFullPath($candidate) }
    }
}

function Resolve-ModelSimBin {
    [CmdletBinding()]
    param([string]$ConfiguredPath, [Parameter(Mandatory = $true)][string]$Workspace)

    if (-not [string]::IsNullOrWhiteSpace($ConfiguredPath)) {
        $configured = ConvertTo-ModelSimFullPath -Path $ConfiguredPath -Workspace $Workspace
        $resolved = Find-ModelSimBinAtPath -Path $configured
        if ($resolved) { return $resolved }
        throw "ModelSim binPath is invalid: $configured. Select a folder containing vlib.exe, vmap.exe, vlog.exe and vsim.exe, or its installation root."
    }
    if (-not [string]::IsNullOrWhiteSpace($env:MODELSIM_BIN)) {
        $configured = ConvertTo-ModelSimFullPath -Path $env:MODELSIM_BIN -Workspace $Workspace
        $resolved = Find-ModelSimBinAtPath -Path $configured
        if ($resolved) { return $resolved }
        throw "MODELSIM_BIN is invalid: $configured. Correct or remove this environment variable."
    }

    foreach ($commandName in @('vsim.exe', 'vlog.exe')) {
        foreach ($command in @(Get-Command $commandName -CommandType Application -All -ErrorAction SilentlyContinue)) {
            $resolved = Find-ModelSimBinAtPath -Path (Split-Path -Parent $command.Source)
            if ($resolved) { return $resolved }
        }
    }

    $simulatorFolders = @('questa_fse', 'questa_fe', 'questa', 'questasim', 'modelsim_ase', 'modelsim_ae', 'modelsim')
    foreach ($drive in @('C:\', 'D:\')) {
        foreach ($vendor in @('intelFPGA', 'intelFPGA_lite', 'altera')) {
            $installRoot = [IO.Path]::Combine($drive, $vendor)
            if (-not (Test-Path -LiteralPath $installRoot -PathType Container)) { continue }
            # Deliberately inspect only known roots and one version level; never recurse.
            $versions = @(Get-ChildItem -LiteralPath $installRoot -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '^\d' } |
                Sort-Object { try { [version]($_.Name -replace '[^0-9.].*$', '') } catch { [version]'0.0' } } -Descending |
                Select-Object -First 30)
            foreach ($versionRoot in @($installRoot) + @($versions | ForEach-Object { $_.FullName })) {
                foreach ($simulator in $simulatorFolders) {
                    $resolved = Find-ModelSimBinAtPath -Path ([IO.Path]::Combine($versionRoot, $simulator))
                    if ($resolved) { return $resolved }
                }
            }
        }
        if (-not (Test-Path -LiteralPath $drive -PathType Container)) { continue }
        $standalone = @(Get-ChildItem -LiteralPath $drive -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^(questa|modelsim|modeltech)' } |
            Sort-Object Name -Descending | Select-Object -First 30)
        foreach ($folder in $standalone) {
            $resolved = Find-ModelSimBinAtPath -Path $folder.FullName
            if ($resolved) { return $resolved }
        }
        foreach ($vendor in @('Siemens', 'MentorGraphics', 'Mentor Graphics', 'Program Files\Siemens', 'Program Files\MentorGraphics', 'Program Files\Mentor Graphics')) {
            $installRoot = [IO.Path]::Combine($drive, $vendor)
            if (-not (Test-Path -LiteralPath $installRoot -PathType Container)) { continue }
            $folders = @(Get-ChildItem -LiteralPath $installRoot -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '(questa|modelsim|modeltech)' } |
                Sort-Object Name -Descending | Select-Object -First 30)
            foreach ($folder in $folders) {
                $resolved = Find-ModelSimBinAtPath -Path $folder.FullName
                if ($resolved) { return $resolved }
            }
        }
    }
    throw 'ModelSim/Questa was not found. Run scripts/setup-modelsim.ps1 -BinPath <installation-or-bin-folder>, or set MODELSIM_BIN.'
}

function Resolve-ModelSimBuildRoot {
    [CmdletBinding()]
    param([string]$ConfiguredPath, [Parameter(Mandatory = $true)][string]$Workspace)

    if (-not [string]::IsNullOrWhiteSpace($ConfiguredPath)) {
        $root = ConvertTo-ModelSimFullPath -Path $ConfiguredPath -Workspace $Workspace
    } else {
        $root = [IO.Path]::Combine([IO.Path]::GetTempPath(), 'Verillog-ModelSim')
        if ($root -match '[^\x00-\x7F]') {
            $publicRoot = $env:PUBLIC
            if (-not $publicRoot) { $publicRoot = [IO.Path]::Combine($env:SystemDrive + '\', 'Users\Public') }
            $root = [IO.Path]::Combine($publicRoot, 'Documents\Verillog-ModelSim')
        }
        $root = [IO.Path]::GetFullPath($root)
    }
    if ($root -match '[^\x00-\x7F]') {
        throw 'ModelSim requires an English-only build path. Set buildRoot in modelsim.local.json, for example C:/VerilogBuild.'
    }
    $workspaceFull = [IO.Path]::GetFullPath($Workspace).TrimEnd('\', '/')
    if ($root.TrimEnd('\', '/').Equals($workspaceFull, [StringComparison]::OrdinalIgnoreCase) -or
        $root.StartsWith($workspaceFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'buildRoot must be outside this workspace to prevent recursive directory junctions.'
    }
    if (Test-Path -LiteralPath $root -PathType Leaf) {
        throw "buildRoot is a file: $root. Select a directory path."
    }
    $root
}
