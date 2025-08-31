# Phase 9: Documentation Generation & Quality Validation
# Generates comprehensive documentation and validates existing docs

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Config
)

# Import common functions
Import-Module "$PSScriptRoot\..\shared\Common-Functions.ps1" -Force

function Invoke-Phase09 {
    param([hashtable]$Config)
    
    Write-Phase "PHASE 9: Documentation Generation & Quality Validation"
    
    Write-Info "Analyzing plugin documentation..."
    
    $documentation = @{
        Existing = @()
        Generated = @()
        Quality = @{
            HasReadme = $false
            HasChangelog = $false
            HasLicense = $false
            HasContributing = $false
            CodeComments = 0
            DocBlocks = 0
            InlineComments = 0
        }
    }
    
    # Check for existing documentation
    $docFiles = @(
        @{ Name = "README.md"; Type = "HasReadme" },
        @{ Name = "readme.txt"; Type = "HasReadme" },
        @{ Name = "CHANGELOG.md"; Type = "HasChangelog" },
        @{ Name = "changelog.txt"; Type = "HasChangelog" },
        @{ Name = "LICENSE"; Type = "HasLicense" },
        @{ Name = "LICENSE.txt"; Type = "HasLicense" },
        @{ Name = "CONTRIBUTING.md"; Type = "HasContributing" }
    )
    
    foreach ($docFile in $docFiles) {
        $filePath = Join-Path $Config.PluginPath $docFile.Name
        if (Test-Path $filePath) {
            $documentation.Existing += $docFile.Name
            $documentation.Quality[$docFile.Type] = $true
            Write-Success "   Found: $($docFile.Name)"
        }
    }
    
    # Analyze code documentation
    Write-Info "Analyzing code documentation quality..."
    $phpFiles = Get-ChildItem -Path $Config.PluginPath -Filter "*.php" -Recurse
    
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        
        # Count DocBlocks
        $docBlocks = ([regex]::Matches($content, '/\*\*[^/]+\*/')).Count
        $documentation.Quality.DocBlocks += $docBlocks
        
        # Count inline comments
        $inlineComments = ([regex]::Matches($content, '//[^\n]+')).Count
        $documentation.Quality.InlineComments += $inlineComments
        
        # Count general comments
        $comments = ([regex]::Matches($content, '/\*[^*][^/]+\*/')).Count
        $documentation.Quality.CodeComments += $comments
    }
    
    $totalComments = $documentation.Quality.DocBlocks + 
                     $documentation.Quality.InlineComments + 
                     $documentation.Quality.CodeComments
    
    Write-Info "   DocBlocks: $($documentation.Quality.DocBlocks)"
    Write-Info "   Inline Comments: $($documentation.Quality.InlineComments)"
    Write-Info "   Block Comments: $($documentation.Quality.CodeComments)"
    
    # Generate API documentation
    Write-Info "Generating API documentation..."
    
    # Load previous phase results for comprehensive docs
    $phase2Results = Get-PhaseResults -Phase "02" -OutputPath $Config.ScanDir
    $phase3Results = Get-PhaseResults -Phase "03" -OutputPath $Config.ScanDir
    $phase4Results = Get-PhaseResults -Phase "04" -OutputPath $Config.ScanDir
    $phase5Results = Get-PhaseResults -Phase "05" -OutputPath $Config.ScanDir
    
    # Extract functions and classes for API docs
    $apiElements = @{
        Functions = @()
        Classes = @()
        Hooks = @()
        Filters = @()
    }
    
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw
        $relativePath = $file.FullName.Replace($Config.PluginPath, "").TrimStart("\")
        
        # Extract functions
        $functions = [regex]::Matches($content, 'function\s+(\w+)\s*\([^)]*\)')
        foreach ($func in $functions) {
            $funcName = $func.Groups[1].Value
            
            # Check if there's a DocBlock above it
            $docBlock = ""
            if ($content -match "(/\*\*[^/]+\*/)\s*function\s+$funcName") {
                $docBlock = $Matches[1]
            }
            
            $apiElements.Functions += @{
                Name = $funcName
                File = $relativePath
                HasDocBlock = ($docBlock -ne "")
                DocBlock = $docBlock
            }
        }
        
        # Extract classes
        $classes = [regex]::Matches($content, 'class\s+(\w+)')
        foreach ($class in $classes) {
            $className = $class.Groups[1].Value
            $apiElements.Classes += @{
                Name = $className
                File = $relativePath
            }
        }
        
        # Extract hooks
        $hooks = [regex]::Matches($content, 'do_action\s*\(\s*['\"]([^'\"]+)['\"]')
        foreach ($hook in $hooks) {
            $hookName = $hook.Groups[1].Value
            $apiElements.Hooks += @{
                Name = $hookName
                File = $relativePath
            }
        }
        
        # Extract filters
        $filters = [regex]::Matches($content, 'apply_filters\s*\(\s*['\"]([^'\"]+)['\"]')
        foreach ($filter in $filters) {
            $filterName = $filter.Groups[1].Value
            $apiElements.Filters += @{
                Name = $filterName
                File = $relativePath
            }
        }
    }
    
    # Generate API documentation
    $apiDoc = @"
# $($Config.PluginName) API Documentation
Generated: $(Get-Date)

## Overview
- Total Functions: $($apiElements.Functions.Count)
- Total Classes: $($apiElements.Classes.Count)
- Custom Hooks: $($apiElements.Hooks.Count)
- Custom Filters: $($apiElements.Filters.Count)

## Functions
$(($apiElements.Functions | Sort-Object Name | ForEach-Object {
"### ``$($_.Name)``
- File: ``$($_.File)``
- Documented: $(if ($_.HasDocBlock) { "Yes" } else { "No" })
"
}) -join "\n")

## Classes
$(($apiElements.Classes | Sort-Object Name | ForEach-Object {
"### ``$($_.Name)``
- File: ``$($_.File)``
"
}) -join "\n")

## Hooks
$(($apiElements.Hooks | Sort-Object Name -Unique | ForEach-Object {
"- ``$($_.Name)``"
}) -join "\n")

## Filters
$(($apiElements.Filters | Sort-Object Name -Unique | ForEach-Object {
"- ``$($_.Name)``"
}) -join "\n")
"@
    
    # Save API documentation
    $apiDocPath = Join-Path $Config.ScanDir "reports\api-documentation.md"
    Ensure-Directory -Path (Split-Path $apiDocPath -Parent)
    $apiDoc | Out-File $apiDocPath
    $documentation.Generated += "api-documentation.md"
    
    # Generate user guide based on findings
    $userGuide = @"
# $($Config.PluginName) User Guide
Generated: $(Get-Date)

## Installation
1. Upload the plugin folder to ``/wp-content/plugins/``
2. Activate the plugin through the 'Plugins' menu in WordPress
3. Configure settings at Settings > $($Config.PluginName)

## Features
$(if ($phase2Results.Features) {
($phase2Results.Features | ForEach-Object { "- $_" }) -join "\n"
} else {
"- Feature detection not available"
})

## Shortcodes
$(if ($apiElements.Filters.Count -gt 0) {
"The following shortcodes are available:\n" +
(($apiElements.Filters | Where-Object { $_.Name -match 'shortcode' } | ForEach-Object {
"- ``[$($_.Name)]`` - Description pending"
}) -join "\n")
} else {
"No shortcodes detected."
})

## Configuration
Refer to the plugin settings page for configuration options.

## Troubleshooting
- Clear cache if changes don't appear
- Check PHP error logs for issues
- Ensure WordPress version compatibility

## Support
For support, please visit the plugin's support forum.
"@
    
    # Save user guide
    $userGuidePath = Join-Path $Config.ScanDir "reports\user-guide.md"
    $userGuide | Out-File $userGuidePath
    $documentation.Generated += "user-guide.md"
    
    # Calculate documentation score
    $score = 0
    $score += $(if ($documentation.Quality.HasReadme) { 25 } else { 0 })
    $score += $(if ($documentation.Quality.HasChangelog) { 15 } else { 0 })
    $score += $(if ($documentation.Quality.HasLicense) { 10 } else { 0 })
    $score += $(if ($documentation.Quality.HasContributing) { 10 } else { 0 })
    
    # Score based on code documentation density
    $codeLines = 0
    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName
        $codeLines += $content.Count
    }
    
    if ($codeLines -gt 0) {
        $commentRatio = $totalComments / $codeLines
        $score += [Math]::Min(40, [Math]::Round($commentRatio * 200))
    }
    
    Write-Host ""
    Write-Host "Documentation Score: $score/100" -ForegroundColor $(
        if ($score -ge 80) { "Green" }
        elseif ($score -ge 60) { "Yellow" }
        else { "Red" }
    )
    
    # Generate final documentation report
    $report = @"
# Documentation Quality Report
Plugin: $($Config.PluginName)
Date: $(Get-Date)
Score: $score/100

## Existing Documentation
- README: $(if ($documentation.Quality.HasReadme) { "✅" } else { "❌" })
- CHANGELOG: $(if ($documentation.Quality.HasChangelog) { "✅" } else { "❌" })
- LICENSE: $(if ($documentation.Quality.HasLicense) { "✅" } else { "❌" })
- CONTRIBUTING: $(if ($documentation.Quality.HasContributing) { "✅" } else { "❌" })

## Code Documentation
- DocBlocks: $($documentation.Quality.DocBlocks)
- Inline Comments: $($documentation.Quality.InlineComments)
- Block Comments: $($documentation.Quality.CodeComments)
- Total Comments: $totalComments
- Code Lines: $codeLines
- Comment Ratio: $([Math]::Round($commentRatio * 100, 2))%

## Generated Documentation
$(($documentation.Generated | ForEach-Object { "- $_" }) -join "\n")

## API Coverage
- Functions with DocBlocks: $(($apiElements.Functions | Where-Object { $_.HasDocBlock }).Count)/$($apiElements.Functions.Count)
- Classes Documented: $($apiElements.Classes.Count)
- Hooks Documented: $($apiElements.Hooks.Count)
- Filters Documented: $($apiElements.Filters.Count)

## Recommendations
$(if (!$documentation.Quality.HasReadme) {
"1. **Add README file** - Essential for user understanding"
})
$(if (!$documentation.Quality.HasChangelog) {
"2. **Add CHANGELOG** - Track version history and updates"
})
$(if (!$documentation.Quality.HasLicense) {
"3. **Add LICENSE file** - Clarify usage rights"
})
$(if ($commentRatio -lt 0.1) {
"4. **Increase code comments** - Current ratio is below 10%"
})
$(if (($apiElements.Functions | Where-Object { !$_.HasDocBlock }).Count -gt 10) {
"5. **Add DocBlocks** - Many functions lack documentation"
})
"@
    
    # Save report
    $reportPath = Join-Path $Config.ScanDir "reports\documentation-report.md"
    $report | Out-File $reportPath
    
    # Save results
    $results = @{
        Score = $score
        Documentation = $documentation
        ApiElements = $apiElements
        CommentRatio = $commentRatio
        ReportPath = $reportPath
        Status = "Completed"
    }
    
    Save-PhaseResults -Phase "09" -Results $results -OutputPath $Config.ScanDir
    
    Write-Success "Documentation generation and validation complete"
    
    return $results
}

# Execute phase if running standalone
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Phase09 -Config $Config
}