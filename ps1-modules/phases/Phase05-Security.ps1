# Phase 5: Security Vulnerability Scanning
# Scans for common WordPress security vulnerabilities

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Config
)

# Import common functions
Import-Module "$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-Phase05 {
    param([hashtable]$Config)
    
    Write-Phase "PHASE 5: Security Vulnerability Scanning"
    
    $vulnerabilities = @{
        Critical = @()
        High = @()
        Medium = @()
        Low = @()
    }
    
    Write-Info "Scanning for security vulnerabilities..."
    
    # Get all PHP files
    $phpFiles = Get-ChildItem -Path $Config.PluginPath -Filter "*.php" -Recurse
    $totalFiles = $phpFiles.Count
    $currentFile = 0
    
    foreach ($file in $phpFiles) {
        $currentFile++
        if ($currentFile % 10 -eq 0) {
            Write-Progress -Activity "Security Scan" -Status "$currentFile of $totalFiles files" -PercentComplete (($currentFile / $totalFiles) * 100)
        }
        
        $content = Get-Content $file.FullName -Raw
        $relativePath = $file.FullName.Replace($Config.PluginPath, "").TrimStart("\")
        
        # 1. Check for eval() usage
        if ($content -match '\beval\s*\([^)]*\$') {
            $vulnerabilities.Critical += @{
                Type = "Code Execution"
                File = $relativePath
                Issue = "eval() with user input detected"
                Line = (Select-String -Path $file.FullName -Pattern 'eval\s*\(' | Select-Object -First 1).LineNumber
            }
        }
        
        # 2. Check for SQL injection vulnerabilities
        if ($content -match '\$wpdb->(query|get_results|get_var|get_row)\s*\([^)]*\$_(GET|POST|REQUEST|COOKIE)') {
            $vulnerabilities.High += @{
                Type = "SQL Injection"
                File = $relativePath
                Issue = "Direct user input in database query"
                Line = (Select-String -Path $file.FullName -Pattern '\$wpdb->' | Select-Object -First 1).LineNumber
            }
        }
        
        # 3. Check for missing nonce verification
        if ($content -match '\$_(GET|POST|REQUEST)\[' -and $content -notmatch 'wp_verify_nonce') {
            $vulnerabilities.Medium += @{
                Type = "CSRF"
                File = $relativePath
                Issue = "Form processing without nonce verification"
            }
        }
        
        # 4. Check for file operations with user input
        if ($content -match '(file_get_contents|fopen|include|require|file_put_contents)\s*\([^)]*\$_(GET|POST|REQUEST)') {
            $vulnerabilities.Critical += @{
                Type = "File Inclusion"
                File = $relativePath
                Issue = "File operation with user input"
            }
        }
        
        # 5. Check for missing capability checks
        if ($content -match 'add_menu_page|add_submenu_page' -and $content -notmatch 'current_user_can') {
            $vulnerabilities.Low += @{
                Type = "Authorization"
                File = $relativePath
                Issue = "Admin page without capability check"
            }
        }
        
        # 6. Check for XSS vulnerabilities
        if ($content -match 'echo\s+\$_(GET|POST|REQUEST|COOKIE)' -and $content -notmatch 'esc_html|esc_attr|sanitize') {
            $vulnerabilities.High += @{
                Type = "XSS"
                File = $relativePath
                Issue = "Unescaped user input in output"
            }
        }
        
        # 7. Check for hardcoded credentials
        if ($content -match '(password|passwd|pwd|api_key|secret)\s*=\s*["\'][^"\']+["\']' -and 
            $content -notmatch '(password_hash|wp_hash_password|\$_ENV|\$_SERVER|getenv)') {
            $vulnerabilities.Medium += @{
                Type = "Hardcoded Credentials"
                File = $relativePath
                Issue = "Possible hardcoded credentials"
            }
        }
    }
    
    Write-Progress -Activity "Security Scan" -Completed
    
    # Calculate security score
    $score = 100
    $score -= $vulnerabilities.Critical.Count * 20
    $score -= $vulnerabilities.High.Count * 10
    $score -= $vulnerabilities.Medium.Count * 5
    $score -= $vulnerabilities.Low.Count * 2
    $score = [Math]::Max(0, $score)
    
    # Display results
    Write-Host ""
    Write-Info "Security Scan Results:"
    Write-Host "   Critical: $($vulnerabilities.Critical.Count)" -ForegroundColor $(if ($vulnerabilities.Critical.Count -gt 0) { "Red" } else { "Green" })
    Write-Host "   High: $($vulnerabilities.High.Count)" -ForegroundColor $(if ($vulnerabilities.High.Count -gt 0) { "Red" } else { "Green" })
    Write-Host "   Medium: $($vulnerabilities.Medium.Count)" -ForegroundColor $(if ($vulnerabilities.Medium.Count -gt 0) { "Yellow" } else { "Green" })
    Write-Host "   Low: $($vulnerabilities.Low.Count)" -ForegroundColor $(if ($vulnerabilities.Low.Count -gt 0) { "Yellow" } else { "Green" })
    Write-Host ""
    Write-Host "   Security Score: $score/100" -ForegroundColor $(
        if ($score -ge 80) { "Green" }
        elseif ($score -ge 60) { "Yellow" }
        else { "Red" }
    )
    
    # Generate security report
    $report = @"
# Security Vulnerability Report
Plugin: $($Config.PluginName)
Date: $(Get-Date)
Score: $score/100

## Summary
- Critical Issues: $($vulnerabilities.Critical.Count)
- High Priority: $($vulnerabilities.High.Count)
- Medium Priority: $($vulnerabilities.Medium.Count)
- Low Priority: $($vulnerabilities.Low.Count)

## Critical Vulnerabilities
$($vulnerabilities.Critical | ForEach-Object {
"### $($_.Type)
- File: ``$($_.File)``
- Issue: $($_.Issue)
$(if ($_.Line) { "- Line: $($_.Line)" })
"
})

## High Priority Issues
$($vulnerabilities.High | ForEach-Object {
"### $($_.Type)
- File: ``$($_.File)``
- Issue: $($_.Issue)
"
})

## Recommendations
$(if ($vulnerabilities.Critical.Count -gt 0) {
"1. **URGENT**: Address all critical vulnerabilities immediately
2. Remove or secure all eval() statements
3. Validate and sanitize all file operations"
})
$(if ($vulnerabilities.High.Count -gt 0) {
"1. Escape all user output with appropriate WordPress functions
2. Use prepared statements for all database queries
3. Implement proper input validation"
})
$(if ($score -lt 60) {
"
⚠️ **This plugin has serious security issues that need immediate attention**"
})
"@
    
    # Save report
    $reportPath = Join-Path $Config.ScanDir "reports\security-report.md"
    Ensure-Directory -Path (Split-Path $reportPath -Parent)
    $report | Out-File $reportPath
    
    # Save results
    $results = @{
        Score = $score
        Vulnerabilities = $vulnerabilities
        TotalIssues = $vulnerabilities.Critical.Count + $vulnerabilities.High.Count + 
                      $vulnerabilities.Medium.Count + $vulnerabilities.Low.Count
        ReportPath = $reportPath
        Status = "Completed"
    }
    
    Save-PhaseResults -Phase "04" -Results $results -OutputPath $Config.ScanDir
    
    Write-Success "Security scan complete. Report saved to: $(Split-Path $reportPath -Leaf)"
    
    return $results
}

# Execute phase if running standalone
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase04 -Config $Config
}