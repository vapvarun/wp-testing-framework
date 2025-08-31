# Common Functions Module for WP Testing Framework
# Shared functions used across all phases

# Color definitions
$Global:colors = @{
    Blue = "Blue"
    Green = "Green"
    Yellow = "Yellow"
    Red = "Red"
    Cyan = "Cyan"
    Magenta = "Magenta"
}

# Output functions
function Write-Phase {
    param([string]$message)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Global:colors.Blue
    Write-Host "🔍 $message" -ForegroundColor $Global:colors.Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Global:colors.Blue
}

function Write-Success {
    param([string]$message)
    Write-Host "✅ $message" -ForegroundColor $Global:colors.Green
}

function Write-Info {
    param([string]$message)
    Write-Host "📊 $message" -ForegroundColor $Global:colors.Cyan
}

function Write-Warning {
    param([string]$message)
    Write-Host "⚠️  $message" -ForegroundColor $Global:colors.Yellow
}

function Write-Error {
    param([string]$message)
    Write-Host "❌ $message" -ForegroundColor $Global:colors.Red
}

# Interactive checkpoint function
function Invoke-Checkpoint {
    param(
        [string]$Phase,
        [string]$Description
    )
    
    if ($Global:Config.InteractiveMode -eq $false) {
        return $true
    }
    
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════" -ForegroundColor $Global:colors.Cyan
    Write-Host "  🔍 CHECKPOINT: $Phase" -ForegroundColor $Global:colors.Cyan
    Write-Host "══════════════════════════════════════════════════" -ForegroundColor $Global:colors.Cyan
    Write-Host ""
    Write-Host "  $Description" -ForegroundColor White
    Write-Host ""
    Write-Host "  Continue? (Y/N/S to skip): " -NoNewline -ForegroundColor $Global:colors.Yellow
    
    $response = Read-Host
    if ($response -eq "S" -or $response -eq "s") {
        return $false
    }
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "Exiting..." -ForegroundColor $Global:colors.Red
        exit 0
    }
    return $true
}

# Function to run command with timeout
function Invoke-WithTimeout {
    param(
        [scriptblock]$ScriptBlock,
        [int]$TimeoutSeconds = 300,
        [string]$TimeoutMessage = "Operation timed out"
    )
    
    $job = Start-Job -ScriptBlock $ScriptBlock
    $result = Wait-Job -Job $job -Timeout $TimeoutSeconds
    
    if ($null -eq $result) {
        Stop-Job -Job $job
        Remove-Job -Job $job -Force
        Write-Warning $TimeoutMessage
        return $null
    }
    
    $output = Receive-Job -Job $job
    Remove-Job -Job $job
    return $output
}

# Function to validate file existence
function Test-PluginExists {
    param([string]$PluginPath)
    
    if (!(Test-Path $PluginPath)) {
        Write-Error "Plugin not found at: $PluginPath"
        return $false
    }
    return $true
}

# Function to create directory if not exists
function Ensure-Directory {
    param([string]$Path)
    
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Success "Created directory: $(Split-Path $Path -Leaf)"
    }
}

# Function to get plugin metadata
function Get-PluginMetadata {
    param([string]$PluginPath)
    
    $metadata = @{
        Name = ""
        Version = ""
        Author = ""
        Description = ""
    }
    
    $pluginFile = Get-ChildItem -Path $PluginPath -Filter "*.php" | 
                  Where-Object { 
                      $content = Get-Content $_.FullName -Raw
                      $content -match "Plugin Name:"
                  } | Select-Object -First 1
    
    if ($pluginFile) {
        $content = Get-Content $pluginFile.FullName -Raw
        
        if ($content -match 'Plugin Name:\s*([^\n]+)') {
            $metadata.Name = $matches[1].Trim()
        }
        if ($content -match 'Version:\s*([^\n]+)') {
            $metadata.Version = $matches[1].Trim()
        }
        if ($content -match 'Author:\s*([^\n]+)') {
            $metadata.Author = $matches[1].Trim()
        }
        if ($content -match 'Description:\s*([^\n]+)') {
            $metadata.Description = $matches[1].Trim()
        }
    }
    
    return $metadata
}

# Function to count files by type
function Get-FileStats {
    param([string]$Path)
    
    $stats = @{
        PHP = (Get-ChildItem -Path $Path -Filter "*.php" -Recurse -ErrorAction SilentlyContinue).Count
        JS = (Get-ChildItem -Path $Path -Filter "*.js" -Recurse -ErrorAction SilentlyContinue).Count
        CSS = (Get-ChildItem -Path $Path -Filter "*.css" -Recurse -ErrorAction SilentlyContinue).Count
        Total = 0
    }
    
    $stats.Total = $stats.PHP + $stats.JS + $stats.CSS
    return $stats
}

# Function to save results
function Save-PhaseResults {
    param(
        [string]$Phase,
        [object]$Results,
        [string]$OutputPath
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $resultsWithMeta = @{
        Phase = $Phase
        Timestamp = $timestamp
        Results = $Results
    }
    
    $jsonPath = Join-Path $OutputPath "phase-$Phase-results.json"
    $resultsWithMeta | ConvertTo-Json -Depth 10 | Out-File $jsonPath
    
    return $jsonPath
}

# Function to load phase results
function Get-PhaseResults {
    param(
        [string]$Phase,
        [string]$OutputPath
    )
    
    $jsonPath = Join-Path $OutputPath "phase-$Phase-results.json"
    if (Test-Path $jsonPath) {
        return Get-Content $jsonPath -Raw | ConvertFrom-Json
    }
    return $null
}

# Export all functions
Export-ModuleMember -Function * -Variable colors