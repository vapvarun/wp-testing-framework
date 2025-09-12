# Phase 7: Test Generation, Execution & Coverage
# Generates three tiers of tests and runs them with coverage analysis

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Config
)

# Import common functions
Import-Module "$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-Phase07 {
    param([hashtable]$Config)
    
    Write-Phase "PHASE 7: Test Generation, Execution & Coverage"
    
    $results = @{
        BasicTests = $false
        ExecutableTests = $false
        SmartTests = $false
        Coverage = 0
        TestsRun = 0
        TestsPassed = 0
        TestsFailed = 0
        Status = "InProgress"
    }
    
    # 1. Generate Basic PHPUnit Tests
    Write-Info "Generating basic PHPUnit test structure..."
    $basicGenerator = Join-Path $Config.FrameworkPath "tools\generate-phpunit-tests.php"
    
    if (Test-Path $basicGenerator) {
        $output = & php $basicGenerator $Config.PluginName 2>&1 | Out-String
        if ($output -match "generated" -or (Test-Path (Join-Path $Config.ScanDir "generated-tests\$($Config.PluginName)Test.php"))) {
            Write-Success "Basic test structure generated"
            $results.BasicTests = $true
        } else {
            Write-Warning "Basic test generation failed"
        }
    }
    
    # 2. Generate Executable Tests
    Write-Info "Generating executable tests for code coverage..."
    $executableGenerator = Join-Path $Config.FrameworkPath "tools\generate-executable-tests.php"
    
    if (Test-Path $executableGenerator) {
        $output = & php $executableGenerator $Config.PluginName 2>&1 | Out-String
        if ($output -match "generated" -or (Test-Path (Join-Path $Config.ScanDir "generated-tests\$($Config.PluginName)ExecutableTest.php"))) {
            Write-Success "Executable tests generated (20-30% coverage potential)"
            $results.ExecutableTests = $true
        }
    }
    
    # 3. Generate AI-Enhanced Smart Tests (if API key available)
    if ($env:ANTHROPIC_API_KEY) {
        Write-Info "Generating AI-enhanced smart tests..."
        $smartGenerator = Join-Path $Config.FrameworkPath "tools\ai\generate-smart-executable-tests.mjs"
        
        if (Test-Path $smartGenerator) {
            $output = & node $smartGenerator $Config.PluginName 2>&1 | Out-String
            if ($output -match "generated" -or (Test-Path (Join-Path $Config.ScanDir "generated-tests\$($Config.PluginName)SmartExecutableTest.php"))) {
                Write-Success "AI-enhanced tests generated (40-60% coverage potential)"
                $results.SmartTests = $true
            }
        }
    } else {
        Write-Warning "Skipping AI test generation (set ANTHROPIC_API_KEY for AI tests)"
    }
    
    # 4. Run Tests with Coverage (if not in quick mode)
    if (!$Config.QuickMode -and ($results.BasicTests -or $results.ExecutableTests -or $results.SmartTests)) {
        Write-Info "Running tests with coverage analysis..."
        
        # Set Xdebug mode for coverage
        $env:XDEBUG_MODE = "coverage"
        
        $testRunner = Join-Path $Config.FrameworkPath "tools\run-unit-tests-with-coverage.php"
        
        if (Test-Path $testRunner) {
            $testOutput = & php $testRunner $Config.PluginName 2>&1 | Out-String
            
            # Parse test results
            if ($testOutput -match "Tests Run: (\d+)") {
                $results.TestsRun = [int]$matches[1]
            }
            if ($testOutput -match "Passed: (\d+)") {
                $results.TestsPassed = [int]$matches[1]
            }
            if ($testOutput -match "Failed: (\d+)") {
                $results.TestsFailed = [int]$matches[1]
            }
            if ($testOutput -match "Coverage: ([\d.]+)%") {
                $results.Coverage = [decimal]$matches[1]
            }
            
            Write-Info "Tests Run: $($results.TestsRun), Passed: $($results.TestsPassed), Failed: $($results.TestsFailed)"
            
            if ($results.Coverage -gt 0) {
                Write-Success "Code Coverage: $($results.Coverage)%"
            } else {
                Write-Warning "Coverage: 0% (tests may need plugin bootstrap)"
            }
        }
    } elseif ($Config.QuickMode) {
        Write-Warning "Skipping test execution in quick mode"
    }
    
    # 5. Generate test report
    $testReport = @"
# Test Generation Report
Plugin: $($Config.PluginName)
Generated: $(Get-Date)

## Tests Generated
- Basic Test Structure: $(if ($results.BasicTests) { "✅" } else { "❌" })
- Executable Tests: $(if ($results.ExecutableTests) { "✅" } else { "❌" })
- AI-Enhanced Tests: $(if ($results.SmartTests) { "✅" } else { "❌" })

## Test Execution
- Tests Run: $($results.TestsRun)
- Tests Passed: $($results.TestsPassed)
- Tests Failed: $($results.TestsFailed)
- Code Coverage: $($results.Coverage)%

## Coverage Targets
- Minimum: 20% (basic functionality)
- Good: 40% (core features)
- Excellent: 60%+ (comprehensive)

## Next Steps
$(if ($results.Coverage -eq 0) {
"1. Ensure plugin is properly loaded in test bootstrap
2. Check that Xdebug is installed with coverage mode
3. Review generated tests for assertions"
} elseif ($results.Coverage -lt 40) {
"1. Add more test cases for uncovered functions
2. Test edge cases and error conditions
3. Add integration tests for WordPress hooks"
} else {
"1. Maintain coverage above 40%
2. Add tests for new features
3. Consider mutation testing for test quality"
})
"@
    
    $testReport | Out-File (Join-Path $Config.ScanDir "reports\test-generation-report.md")
    
    # Save results
    $results.Status = "Completed"
    Save-PhaseResults -Phase "06" -Results $results -OutputPath $Config.ScanDir
    
    Write-Success "Test generation and execution complete"
    
    return $results
}

# Execute phase if running standalone
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase06 -Config $Config
}