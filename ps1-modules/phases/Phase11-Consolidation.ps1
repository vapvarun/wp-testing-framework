# Phase 11: Consolidating All Reports
# Combines all phase results into a comprehensive final report

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Config
)

# Import common functions
Import-Module "$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-Phase11 {
    param([hashtable]$Config)
    
    Write-Phase "PHASE 11: Consolidating All Reports"
    
    Write-Info "Gathering results from all phases..."
    
    # Collect all phase results
    $allResults = @{}
    $availablePhases = @()
    $missingPhases = @()
    
    for ($i = 1; $i -le 9; $i++) {
        $phaseNum = $i.ToString().PadLeft(2, '0')
        $phaseResults = Get-PhaseResults -Phase $phaseNum -OutputPath $Config.ScanDir
        
        if ($phaseResults) {
            $allResults["Phase$i"] = $phaseResults
            $availablePhases += $i
            Write-Success "   Phase $i results loaded"
        } else {
            $missingPhases += $i
            Write-Warning "   Phase $i results not found"
        }
    }
    
    # Calculate overall metrics
    $overallMetrics = @{
        TotalPhases = 9
        CompletedPhases = $availablePhases.Count
        SkippedPhases = $missingPhases.Count
        AverageScore = 0
        CriticalIssues = 0
        Warnings = 0
        Recommendations = @()
    }
    
    # Calculate average score from phases that have scores
    $scores = @()
    foreach ($phase in $allResults.Values) {
        if ($phase.Score) {
            $scores += $phase.Score
        }
    }
    
    if ($scores.Count -gt 0) {
        $overallMetrics.AverageScore = [Math]::Round(($scores | Measure-Object -Average).Average, 2)
    }
    
    # Collect critical issues and warnings
    if ($allResults.Phase4) {  # Security
        if ($allResults.Phase4.Vulnerabilities) {
            $overallMetrics.CriticalIssues += $allResults.Phase4.Vulnerabilities.Critical.Count
            $overallMetrics.CriticalIssues += $allResults.Phase4.Vulnerabilities.High.Count
            $overallMetrics.Warnings += $allResults.Phase4.Vulnerabilities.Medium.Count
            $overallMetrics.Warnings += $allResults.Phase4.Vulnerabilities.Low.Count
        }
    }
    
    # Generate consolidated report
    Write-Info "Generating consolidated report..."
    
    $consolidatedReport = @"
# WordPress Plugin Testing Framework - Final Report
# $($Config.PluginName)
Generated: $(Get-Date)
Framework Version: 12.0

## Executive Summary
- **Plugin**: $($Config.PluginName)
- **Test Mode**: $($Config.Mode)
- **Overall Score**: $($overallMetrics.AverageScore)/100
- **Critical Issues**: $($overallMetrics.CriticalIssues)
- **Warnings**: $($overallMetrics.Warnings)
- **Phases Completed**: $($overallMetrics.CompletedPhases)/$($overallMetrics.TotalPhases)

## Phase Results Summary

"@
    
    # Add individual phase summaries
    $phaseNames = @{
        1 = "Setup & Directory Structure"
        2 = "Plugin Detection & Basic Analysis"
        3 = "AI-Driven Code Analysis"
        4 = "Security Vulnerability Scanning"
        5 = "Performance Analysis"
        6 = "Test Generation & Coverage"
        7 = "Visual Testing & Screenshots"
        8 = "WordPress Integration Tests"
        9 = "Documentation Quality"
    }
    
    foreach ($i in 1..9) {
        $phase = $allResults["Phase$i"]
        $phaseName = $phaseNames[$i]
        
        if ($phase) {
            $status = if ($phase.Status -eq "Completed") { "✅" } 
                     elseif ($phase.Status -eq "Skipped") { "⏭" }
                     else { "❌" }
            
            $consolidatedReport += @"
### Phase $i: $phaseName $status
$(if ($phase.Score) { "- **Score**: $($phase.Score)/100" })
$(if ($phase.Status) { "- **Status**: $($phase.Status)" })
$(if ($phase.ReportPath) { "- **Report**: [View Report]($(Split-Path $phase.ReportPath -Leaf))" })

"@
            
            # Add phase-specific highlights
            switch ($i) {
                2 {  # Detection
                    if ($phase.PluginInfo) {
                        $consolidatedReport += @"
- Plugin Version: $($phase.PluginInfo.Version)
- PHP Files: $($phase.FileStats.PHPFiles)
- JavaScript Files: $($phase.FileStats.JSFiles)

"@
                    }
                }
                4 {  # Security
                    if ($phase.Vulnerabilities) {
                        $consolidatedReport += @"
- Critical: $($phase.Vulnerabilities.Critical.Count)
- High: $($phase.Vulnerabilities.High.Count)
- Medium: $($phase.Vulnerabilities.Medium.Count)
- Low: $($phase.Vulnerabilities.Low.Count)

"@
                    }
                }
                5 {  # Performance
                    if ($phase.DatabaseMetrics) {
                        $consolidatedReport += @"
- Database Operations: $($phase.DatabaseMetrics.TotalQueries)
- Caching Implemented: $(if ($phase.CacheMetrics -and !$phase.CacheMetrics.NoCaching) { "Yes" } else { "No" })

"@
                    }
                }
                6 {  # Testing
                    if ($phase.TestResults) {
                        $consolidatedReport += @"
- Tests Generated: $($phase.TestResults.TestsGenerated)
- Coverage: $($phase.TestResults.Coverage)%

"@
                    }
                }
            }
        } else {
            $consolidatedReport += @"
### Phase $i: $phaseName ⏭
- **Status**: Not Run

"@
        }
    }
    
    # Add key findings section
    $consolidatedReport += @"
## Key Findings

### Strengths
$(if ($overallMetrics.AverageScore -ge 80) {
"- Excellent overall code quality"
})
$(if ($allResults.Phase4 -and $allResults.Phase4.Score -ge 80) {
"- Strong security posture"
})
$(if ($allResults.Phase5 -and $allResults.Phase5.Score -ge 80) {
"- Good performance optimization"
})
$(if ($allResults.Phase9 -and $allResults.Phase9.Score -ge 80) {
"- Well documented"
})

### Areas for Improvement
$(if ($overallMetrics.CriticalIssues -gt 0) {
"- **Critical**: $($overallMetrics.CriticalIssues) security vulnerabilities need immediate attention"
})
$(if ($allResults.Phase5 -and $allResults.Phase5.CacheMetrics -and $allResults.Phase5.CacheMetrics.NoCaching) {
"- Implement caching for better performance"
})
$(if ($allResults.Phase9 -and $allResults.Phase9.Score -lt 60) {
"- Improve code documentation"
})
$(if ($allResults.Phase6 -and $allResults.Phase6.TestResults -and $allResults.Phase6.TestResults.Coverage -lt 50) {
"- Increase test coverage (currently $($allResults.Phase6.TestResults.Coverage)%)"
})

## Recommendations Priority

### High Priority
$(if ($overallMetrics.CriticalIssues -gt 0) {
"1. Fix all critical security vulnerabilities"
})
$(if ($allResults.Phase4 -and $allResults.Phase4.Vulnerabilities -and $allResults.Phase4.Vulnerabilities.High.Count -gt 0) {
"2. Address high-priority security issues"
})

### Medium Priority
$(if ($allResults.Phase5 -and $allResults.Phase5.Score -lt 60) {
"3. Optimize performance bottlenecks"
})
$(if ($allResults.Phase6 -and $allResults.Phase6.TestResults -and $allResults.Phase6.TestResults.Coverage -lt 30) {
"4. Increase test coverage"
})

### Low Priority
$(if ($allResults.Phase9 -and !$allResults.Phase9.Documentation.Quality.HasChangelog) {
"5. Add changelog documentation"
})
$(if ($allResults.Phase8 -and $allResults.Phase8.TotalIntegrations -lt 10) {
"6. Enhance WordPress integration"
})

## Test Artifacts

### Reports Generated
"@
    
    # List all generated reports
    $reportsDir = Join-Path $Config.ScanDir "reports"
    if (Test-Path $reportsDir) {
        $reports = Get-ChildItem $reportsDir -Filter "*.md" -ErrorAction SilentlyContinue
        foreach ($report in $reports) {
            $consolidatedReport += "- [$($report.Name)]($($report.Name))`n"
        }
    }
    
    # Add test results if available
    if ($allResults.Phase6 -and $allResults.Phase6.TestResults) {
        $consolidatedReport += @"

### Test Results
- Tests Generated: $($allResults.Phase6.TestResults.TestsGenerated)
- Tests Passed: $($allResults.Phase6.TestResults.TestsPassed)
- Tests Failed: $($allResults.Phase6.TestResults.TestsFailed)
- Coverage: $($allResults.Phase6.TestResults.Coverage)%
"@
    }
    
    # Add metadata
    $consolidatedReport += @"

## Metadata
- **Framework Version**: 12.0
- **Scan Date**: $(Get-Date)
- **Plugin Path**: $($Config.PluginPath)
- **Scan Directory**: $($Config.ScanDir)
- **Mode**: $($Config.Mode)
- **Interactive**: $(if ($Config.InteractiveMode) { "Yes" } else { "No" })

---
*Generated by WordPress Plugin Testing Framework v12.0*
"@
    
    # Save consolidated report
    $consolidatedReportPath = Join-Path $Config.ScanDir "FINAL-REPORT.md"
    $consolidatedReport | Out-File $consolidatedReportPath
    
    # Generate JSON summary for programmatic access
    $jsonSummary = @{
        Plugin = $Config.PluginName
        Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        OverallScore = $overallMetrics.AverageScore
        CriticalIssues = $overallMetrics.CriticalIssues
        Warnings = $overallMetrics.Warnings
        PhasesCompleted = $overallMetrics.CompletedPhases
        TotalPhases = $overallMetrics.TotalPhases
        PhaseScores = @{}
    }
    
    foreach ($i in $availablePhases) {
        if ($allResults["Phase$i"].Score) {
            $jsonSummary.PhaseScores["Phase$i"] = $allResults["Phase$i"].Score
        }
    }
    
    $jsonPath = Join-Path $Config.ScanDir "summary.json"
    $jsonSummary | ConvertTo-Json -Depth 5 | Out-File $jsonPath
    
    # Display summary
    Write-Host ""
    Write-Host "════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "              FINAL ANALYSIS COMPLETE            " -ForegroundColor Blue
    Write-Host "════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Plugin: $($Config.PluginName)" -ForegroundColor White
    Write-Host "Overall Score: $($overallMetrics.AverageScore)/100" -ForegroundColor $(
        if ($overallMetrics.AverageScore -ge 80) { "Green" }
        elseif ($overallMetrics.AverageScore -ge 60) { "Yellow" }
        else { "Red" }
    )
    Write-Host ""
    Write-Host "Critical Issues: $($overallMetrics.CriticalIssues)" -ForegroundColor $(if ($overallMetrics.CriticalIssues -gt 0) { "Red" } else { "Green" })
    Write-Host "Warnings: $($overallMetrics.Warnings)" -ForegroundColor $(if ($overallMetrics.Warnings -gt 5) { "Yellow" } else { "Green" })
    Write-Host ""
    Write-Host "Reports saved to: $consolidatedReportPath" -ForegroundColor Cyan
    Write-Host "JSON summary: $jsonPath" -ForegroundColor Cyan
    
    # Save results
    $results = @{
        OverallMetrics = $overallMetrics
        ConsolidatedReportPath = $consolidatedReportPath
        JsonSummaryPath = $jsonPath
        AllPhaseResults = $allResults
        Status = "Completed"
    }
    
    Save-PhaseResults -Phase "10" -Results $results -OutputPath $Config.ScanDir
    
    Write-Success "All reports consolidated successfully!"
    
    return $results
}

# Execute phase if running standalone
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase10 -Config $Config
}