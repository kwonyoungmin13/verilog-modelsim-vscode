[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SourcePath,
    [ValidateSet('Gui', 'Batch', 'Compile')][string]$Action = 'Gui',
    [string]$Top,
    [string]$RunTime
)

$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot

function Invoke-ModelSimTool {
    param([string]$Name, [string[]]$ToolArguments)
    # Legacy ModelSim emits the Windows ANSI encoding (CP949 on this computer).
    # Decode first, then restore UTF-8 output so Korean error paths remain clickable.
    $previousEncoding = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [Text.Encoding]::Default
        $toolOutput = @(& (Join-Path $script:binPath ($Name + '.exe')) @ToolArguments)
        $toolExit = $LASTEXITCODE
    } finally {
        [Console]::OutputEncoding = $previousEncoding
    }
    $toolOutput | ForEach-Object {
        $line = [string]$_
        if ($script:workspaceAlias) {
            $line = $line.Replace($script:workspaceAlias, $script:workspace)
            $line = $line.Replace(($script:workspaceAlias -replace '\\', '/'), ($script:workspace -replace '\\', '/'))
        }
        Write-Output $line
    }
    if ($toolExit -ne 0) {
        throw "$Name failed (exit $toolExit). See the compiler/simulator output above."
    }
}

try {
    . (Join-Path $PSScriptRoot 'modelsim-common.ps1')
    $config = Get-ModelSimConfiguration -Workspace $workspace
    $binPath = Resolve-ModelSimBin -ConfiguredPath $config.binPath -Workspace $workspace
    if (-not $RunTime) { $RunTime = $config.runTime }
    if ($RunTime -notmatch '^\d+(?:\.\d+)?\s*(?:fs|ps|ns|us|ms|sec)$') {
        throw 'runTime must be a finite duration such as "1 us" or "500 ns".'
    }
    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf) -or
        [IO.Path]::GetExtension($SourcePath) -notin @('.v', '.sv', '.vh', '.svh')) {
        throw 'Open a saved Verilog (.v) or SystemVerilog (.sv) file, then press Ctrl+Shift+B.'
    }
    $sourceFile = Get-Item -LiteralPath $SourcePath
    $projectDir = $sourceFile.Directory.FullName
    if (-not ($projectDir.Equals($workspace, [StringComparison]::OrdinalIgnoreCase) -or
        $projectDir.StartsWith($workspace + '\', [StringComparison]::OrdinalIgnoreCase))) {
        throw 'The selected Verilog file must be inside this workspace.'
    }
    # One circuit per folder. Use files.f for nested sources or explicit package ordering.
    $fileList = Join-Path $projectDir 'files.f'
    if (Test-Path -LiteralPath $fileList) {
        $sources = @(Get-Content -LiteralPath $fileList -Encoding UTF8 | ForEach-Object {
            $entry = ($_ -replace '\s*//.*$', '').Trim().Trim('"')
            if ($entry -and -not $entry.StartsWith('#')) {
                $candidate = Join-Path $projectDir $entry
                if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
                    throw "files.f source not found: $entry"
                }
                (Get-Item -LiteralPath $candidate).FullName
            }
        })
    } else {
        $sources = @(Get-ChildItem -LiteralPath $projectDir -File |
            Where-Object { $_.Extension -in @('.v', '.sv') } |
            Sort-Object Name | ForEach-Object { $_.FullName })
    }
    if ($sources.Count -eq 0) { throw "No .v or .sv sources found in $projectDir." }

    if (-not $Top) { $Top = $config.top }
    if (-not $Top -and $Action -ne 'Compile') {
        $activeModules = @()
        $modules = @(foreach ($source in $sources) {
            $code = Get-Content -LiteralPath $source -Raw -Encoding UTF8
            $code = [regex]::Replace($code, '(?s)/\*.*?\*/|//[^\r\n]*', '')
            foreach ($match in [regex]::Matches($code, '\bmodule\s+(?:(?:automatic|static)\s+)?([A-Za-z_][A-Za-z0-9_$]*)')) {
                $moduleName = $match.Groups[1].Value
                if ($source.Equals($sourceFile.FullName, [StringComparison]::OrdinalIgnoreCase)) {
                    $activeModules += $moduleName
                }
                $moduleName
            }
        })
        $testbenches = @($modules | Where-Object { $_ -match '(?i)(^tb_|_tb$|testbench)' } | Select-Object -Unique)
        $base = $sourceFile.BaseName
        # Prefer the active module, even if its name differs from the filename.
        $preferred = @($activeModules | Where-Object { $testbenches -contains $_ })
        foreach ($moduleName in $activeModules) {
            $preferred += @(($moduleName + '_tb'), ('tb_' + $moduleName))
        }
        $preferred += @($base, ($base + '_tb'), ('tb_' + $base))
        foreach ($name in $preferred) {
            if ($testbenches -contains $name) { $Top = $name; break }
        }
        if (-not $Top -and $testbenches.Count -eq 1) { $Top = $testbenches[0] }
        if (-not $Top) {
            throw 'Cannot choose a testbench. Open its source file, name it <module>_tb (or tb_<module>), or set top in modelsim.local.json.'
        }
    }
    if ($Top -and $Top -notmatch '^[A-Za-z_][A-Za-z0-9_$]*$') {
        throw 'top must be a simple Verilog module name, for example counter_tb.'
    }

    # Separate runs avoid locks held by an already open ModelSim waveform window.
    $projectName = $projectDir.Substring($workspace.Length).TrimStart('\', '/') -replace '[^A-Za-z0-9_.-]', '_'
    if (-not $projectName) { $projectName = 'root' }
    $runId = (Get-Date -Format 'yyyyMMdd_HHmmss_fff') + '_' + [guid]::NewGuid().ToString('N').Substring(0, 6)
    # Both the SQLite library and GUI layout keys fail on Korean paths in ModelSim 2020.1.
    # Use a real ASCII run directory, plus a junction to access the original source files.
    $tempRoot = Resolve-ModelSimBuildRoot -ConfiguredPath $config.buildRoot -Workspace $workspace
    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
        $workspaceId = ([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($workspace.ToLowerInvariant())))).Replace('-', '').Substring(0, 16)
    } finally { $hasher.Dispose() }
    $workspaceAlias = Join-Path $tempRoot ('workspace_' + $workspaceId)
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    if (Test-Path -LiteralPath $workspaceAlias) {
        $link = Get-Item -LiteralPath $workspaceAlias
        if ($link.LinkType -ne 'Junction' -or $link.Target -notcontains $workspace) {
            throw "Unexpected existing path: $workspaceAlias. It must be a junction to this workspace."
        }
    } else {
        New-Item -ItemType Junction -Path $workspaceAlias -Target $workspace | Out-Null
    }
    $modelSources = @(foreach ($source in $sources) {
        if (-not $source.StartsWith($workspace + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw 'All files.f sources must be inside this workspace.'
        }
        $workspaceAlias + $source.Substring($workspace.Length)
    })
    $modelProjectDir = $workspaceAlias + $projectDir.Substring($workspace.Length)
    $buildDir = Join-Path $tempRoot ('runs/' + $workspaceId + '/' + $projectName + '/' + $runId)
    $resultDir = Join-Path $workspace ('.modelsim/' + $projectName + '/' + $runId)
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path -Parent $resultDir) -Force | Out-Null
    # Expose actual output files at .modelsim/... while ModelSim itself uses only the ASCII path.
    New-Item -ItemType Junction -Path $resultDir -Target $buildDir | Out-Null
    Push-Location -LiteralPath $buildDir
    try {
        Invoke-ModelSimTool 'vmap' @('-c')
        Invoke-ModelSimTool 'vlib' @('work')
        Invoke-ModelSimTool 'vmap' @('work', 'work')
        $compileArgs = @('-sv', '-work', 'work', ('+incdir+' + $modelProjectDir)) + $modelSources
        Invoke-ModelSimTool 'vlog' $compileArgs
        Write-Host "`nCOMPILE OK: $projectDir"
        if ($Action -eq 'Compile') { exit 0 }

        # This macro contains no absolute paths, keeping Tcl independent of Windows path encoding.
        $macro = @(
            'onerror {quit -force -code 1}',
            'onbreak {resume}',
            ('vsim -onfinish stop -voptargs=+acc -wlf waves.wlf work.' + $Top),
            'if {[llength [find signals -r sim:/*]] > 0} {log -r sim:/*}'
        )
        if ($Action -eq 'Gui') {
            $macro += @(
                'view wave',
                'radix binary',
                ('if {[llength [find signals sim:/' + $Top + '/*]] > 0} {add wave -radix binary sim:/' + $Top + '/*}')
            )
        }
        $macro += @(
            ('run ' + $RunTime),
            # ModelSim returns exit 0 for $fatal with -onfinish stop. Check its flushed transcript.
            'transcript off',
            'quietly set logFile [open simulation.log r]',
            'quietly set logText [read $logFile]',
            'close $logFile',
            'transcript on',
            'if {[regexp {(^|\n)#?\s*\*\* (Error|Fatal):} $logText]} {quit -force -code 1}'
        )
        if ($Action -eq 'Gui') {
            $macro += @('view wave', 'wave zoom full', 'write format wave wave.do')
        }
        $macro += @(
            'set ready [open simulation.ready w]',
            'puts $ready "Simulation completed"',
            'close $ready'
        )
        if ($Action -eq 'Batch') { $macro += 'quit -force -code 0' }
        Set-Content -LiteralPath 'run.do' -Value $macro -Encoding ASCII
        Write-Host "TOP: $Top | RUN: $RunTime"
        Write-Host "OUTPUT: $resultDir"
        if ($Action -eq 'Batch') {
            Invoke-ModelSimTool 'vsim' @('-c', '-l', 'simulation.log', '-do', 'run.do')
            if (-not (Test-Path -LiteralPath 'simulation.ready')) { throw 'Simulation did not complete.' }
            Write-Host 'SIMULATION OK (waves.wlf saved).'
        } else {
            # Visible GUI is intentional: this is the waveform window requested by the user.
            $process = Start-Process -FilePath (Join-Path $binPath 'vsim.exe') -WorkingDirectory $buildDir `
                -ArgumentList @('-gui', '-l', 'simulation.log', '-do', 'run.do') -WindowStyle Normal -PassThru
            Write-Host "ModelSim GUI launched (PID $($process.Id)). Waveform opens automatically."
        }
    } finally {
        Pop-Location
    }
} catch {
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
