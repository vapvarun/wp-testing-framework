# Phase 4: AI-Driven Code Analysis
# Performs AST analysis, dynamic test data generation, and code analysis

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Config
)

# Import common functions
Import-Module "$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-Phase04 {
    param([hashtable]$Config)
    
    Write-Phase "PHASE 4: AI-Driven Code Analysis"
    
    # Check if we should skip this phase
    if ($Config.QuickMode) {
        Write-Warning "Skipping detailed analysis in quick mode"
        return @{ Status = "Skipped"; Reason = "Quick mode" }
    }
    
    # Interactive checkpoint
    if (!(Invoke-Checkpoint -Phase "AI Analysis" -Description "This phase performs comprehensive code analysis using AST parsing and AI-driven pattern detection. Large plugins may take 5-10 minutes.")) {
        return @{ Status = "Skipped"; Reason = "User skipped" }
    }
    
    $results = @{
        AST = $null
        DynamicData = $null
        PHPStan = $null
        FileAnalysis = @{}
        PluginCheck = $null
        Status = "InProgress"
    }
    
    # 1. Load Plugin Check Results (from Phase 3)
    Write-Info "Loading Plugin Check results..."
    $pluginCheckDir = Join-Path $Config.ScanDir "plugin-check"
    $pluginCheckJson = Join-Path $pluginCheckDir "plugin-check-full.json"
    
    if (Test-Path $pluginCheckJson) {
        try {
            $pluginCheckContent = Get-Content $pluginCheckJson -Raw
            if ($pluginCheckContent.Trim()) {
                $pluginCheckData = $pluginCheckContent | ConvertFrom-Json
                $results.PluginCheck = @{
                    ErrorCount = ($pluginCheckData | Where-Object { $_.type -eq "ERROR" }).Count
                    WarningCount = ($pluginCheckData | Where-Object { $_.type -eq "WARNING" }).Count
                    Categories = ($pluginCheckData | ForEach-Object { $_.category } | Where-Object { $_ } | Sort-Object -Unique)
                    SecurityIssues = ($pluginCheckData | Where-Object { $_.category -like "*security*" -or $_.code -like "*escaping*" -or $_.code -like "*sql*" }).Count
                    PerformanceIssues = ($pluginCheckData | Where-Object { $_.category -like "*performance*" -or $_.code -like "*script*" -or $_.code -like "*style*" }).Count
                }
                Write-Info "Plugin Check data loaded: $($results.PluginCheck.ErrorCount) errors, $($results.PluginCheck.WarningCount) warnings"
            }
        }
        catch {
            Write-Warning "Failed to parse Plugin Check results: $_"
        }
    } else {
        Write-Warning "Plugin Check results not found. Run Phase 3 first."
    }
    
    # 2. WordPress AST Analysis
    Write-Info "Running WordPress AST Analysis..."
    $astAnalyzer = Join-Path $Config.FrameworkPath "tools\wordpress-ast-analyzer.js"
    
    if (Test-Path $astAnalyzer) {
        $astOutput = Invoke-WithTimeout -ScriptBlock {
            & node $astAnalyzer $Config.PluginPath 2>&1 | Out-String
        } -TimeoutSeconds 300 -TimeoutMessage "AST analysis timed out (5 minutes)"
        
        if ($astOutput) {
            Write-Success "AST analysis completed"
            
            # Parse AST results
            $astFile = Join-Path $Config.ScanDir "wordpress-ast-analysis.json"
            if (Test-Path $astFile) {
                $astData = Get-Content $astFile -Raw | ConvertFrom-Json
                $results.AST = @{
                    Functions = $astData.summary.functions
                    Classes = $astData.summary.classes
                    Methods = $astData.summary.methods
                    Hooks = $astData.details.hooks.Count
                    Shortcodes = $astData.details.shortcodes.Count
                    AjaxHandlers = $astData.details.ajax_handlers.Count
                }
                
                Write-Info "Detected: $($results.AST.Functions) functions, $($results.AST.Classes) classes, $($results.AST.Hooks) hooks"
            }
        }
    } else {
        Write-Warning "AST analyzer not found"
    }
    
    # 3. Dynamic Test Data Generation
    Write-Info "Generating dynamic test data..."
    $dataGenerator = Join-Path $Config.FrameworkPath "tools\ai\dynamic-test-data-generator.mjs"
    
    if (Test-Path $dataGenerator) {
        $dataOutput = & node $dataGenerator $Config.PluginName 2>&1 | Out-String
        if ($dataOutput -match "scenarios detected") {
            Write-Success "Dynamic test data generated"
            $results.DynamicData = "Generated"
        }
    }
    
    # 4. PHPStan Analysis (if available)
    if ($Config.UsePHPStan) {
        Write-Info "Running PHPStan analysis..."
        $phpstanConfig = Join-Path $Config.FrameworkPath "phpstan.neon"
        
        if ((Get-Command phpstan -ErrorAction SilentlyContinue) -or 
            (Test-Path (Join-Path $Config.FrameworkPath "vendor\bin\phpstan"))) {
            
            $phpstanCmd = if (Get-Command phpstan -ErrorAction SilentlyContinue) { 
                "phpstan" 
            } else { 
                Join-Path $Config.FrameworkPath "vendor\bin\phpstan"
            }
            
            $phpstanOutput = & $phpstanCmd analyze $Config.PluginPath --level=5 --no-progress 2>&1 | Out-String
            
            if ($phpstanOutput -match "(\d+) errors?") {
                $errorCount = $matches[1]
                Write-Info "PHPStan found $errorCount issues"
                $results.PHPStan = @{
                    Errors = $errorCount
                    Output = $phpstanOutput
                }
            }
        }
    }
    
    # 5. File-level analysis
    Write-Info "Performing file-level analysis..."
    
    # Get all PHP files
    $phpFiles = Get-ChildItem -Path $Config.PluginPath -Filter "*.php" -Recurse
    
    # Analyze complexity of largest files
    $largeFiles = $phpFiles | Sort-Object Length -Descending | Select-Object -First 5
    
    foreach ($file in $largeFiles) {
        $content = Get-Content $file.FullName -Raw
        $results.FileAnalysis[$file.Name] = @{
            Size = [math]::Round($file.Length / 1KB, 2)
            Lines = ($content -split "`n").Count
            Functions = ([regex]::Matches($content, 'function\s+\w+')).Count
            Classes = ([regex]::Matches($content, 'class\s+\w+')).Count
        }
    }
    
    # 6. WordPress pattern detection
    Write-Info "Detecting WordPress patterns..."
    
    $patterns = @{
        CustomPostTypes = 0
        CustomTaxonomies = 0
        AdminPages = 0
        RestEndpoints = 0
        GutenbergBlocks = 0
    }
    
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        $patterns.CustomPostTypes += ([regex]::Matches($content, 'register_post_type\s*\(')).Count
        $patterns.CustomTaxonomies += ([regex]::Matches($content, 'register_taxonomy\s*\(')).Count
        $patterns.AdminPages += ([regex]::Matches($content, 'add_menu_page\s*\(')).Count
        $patterns.RestEndpoints += ([regex]::Matches($content, 'register_rest_route\s*\(')).Count
        $patterns.GutenbergBlocks += ([regex]::Matches($content, 'registerBlockType\s*\(')).Count
    }
    
    $results.Patterns = $patterns
    
    # Save results
    $results.Status = "Completed"
    Save-PhaseResults -Phase "04" -Results $results -OutputPath $Config.ScanDir
    
    Write-Success "Code analysis complete"
    
    return $results
}

# Execute phase if running standalone
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase04 -Config $Config
}