# ============================================
# WordPress Plugin Check Setup Tool (PowerShell)
# Version: 1.0.0
# Purpose: Setup and configure Plugin Check as a data source for Windows
# ============================================

param(
    [Parameter(Mandatory=$false)]
    [string]$WPPath = (Get-Location).Path
)

# Set error handling
$ErrorActionPreference = "Stop"

# Color definitions
$Global:colors = @{
    Blue = "Blue"
    Green = "Green"
    Yellow = "Yellow"
    Red = "Red"
    Cyan = "Cyan"
}

# Functions
function Write-Info {
    param([string]$message)
    Write-Host "📊 $message" -ForegroundColor $Global:colors.Blue
}

function Write-Success {
    param([string]$message)
    Write-Host "✅ $message" -ForegroundColor $Global:colors.Green
}

function Write-Error {
    param([string]$message)
    Write-Host "❌ $message" -ForegroundColor $Global:colors.Red
}

function Write-Warning {
    param([string]$message)
    Write-Host "⚠️  $message" -ForegroundColor $Global:colors.Yellow
}

# Header
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor $Global:colors.Blue
Write-Host "║       WordPress Plugin Check Setup Tool                ║" -ForegroundColor $Global:colors.Blue
Write-Host "║   Configure Plugin Check as Testing Data Source        ║" -ForegroundColor $Global:colors.Blue
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor $Global:colors.Blue
Write-Host ""

# Find WordPress root
if (-not (Test-Path (Join-Path $WPPath "wp-config.php"))) {
    Write-Error "WordPress not found at $WPPath"
    exit 1
}

$PluginCheckPath = Join-Path $WPPath "wp-content\plugins\plugin-check"

# Step 1: Install Plugin Check
Write-Info "Step 1: Installing WordPress Plugin Check..."

if (-not (Test-Path $PluginCheckPath)) {
    try {
        $installResult = & wp plugin install plugin-check --path="$WPPath" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install Plugin Check: $installResult"
            exit 1
        }
        Write-Success "Plugin Check installed"
    }
    catch {
        Write-Error "Failed to install Plugin Check: $_"
        exit 1
    }
} else {
    Write-Success "Plugin Check already installed"
}

# Step 2: Install Composer dependencies
Write-Info "Step 2: Installing Composer dependencies..."

$composerJsonPath = Join-Path $PluginCheckPath "composer.json"
if (Test-Path $composerJsonPath) {
    Push-Location $PluginCheckPath
    
    if (Get-Command composer -ErrorAction SilentlyContinue) {
        Write-Host "Running: composer install" -ForegroundColor Gray
        try {
            $composerResult = & composer install --no-dev --optimize-autoloader 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Standard install failed. Trying with --ignore-platform-reqs..."
                $composerResult = & composer install --no-dev --optimize-autoloader --ignore-platform-reqs 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Composer install failed: $composerResult"
                }
            }
            Write-Success "Composer dependencies installed"
        }
        catch {
            Write-Error "Composer install failed: $_"
        }
    } else {
        Write-Warning "Composer not found. Installing Composer locally..."
        
        try {
            # Download Composer installer
            Invoke-WebRequest -Uri "https://getcomposer.org/installer" -OutFile "composer-setup.php"
            
            # Install Composer
            & php composer-setup.php 2>&1 | Out-Null
            Remove-Item "composer-setup.php" -ErrorAction SilentlyContinue
            
            if (Test-Path "composer.phar") {
                & php composer.phar install --no-dev --optimize-autoloader 2>&1 | Out-Null
                Write-Success "Composer dependencies installed with local Composer"
            } else {
                Write-Error "Failed to install Composer"
            }
        }
        catch {
            Write-Error "Failed to install Composer: $_"
        }
    }
    
    Pop-Location
} else {
    Write-Info "No composer.json found in Plugin Check"
}

# Step 3: Install npm dependencies
Write-Info "Step 3: Installing npm dependencies..."

$packageJsonPath = Join-Path $PluginCheckPath "package.json"
if (Test-Path $packageJsonPath) {
    Push-Location $PluginCheckPath
    
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Host "Running: npm install" -ForegroundColor Gray
        try {
            $npmResult = & npm install 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Standard install failed. Trying with --force..."
                $npmResult = & npm install --force 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "npm install failed: $npmResult"
                }
            }
            
            # Build assets if build script exists
            $packageContent = Get-Content "package.json" -Raw
            if ($packageContent -match '"build"') {
                Write-Info "Building Plugin Check assets..."
                try {
                    & npm run build 2>&1 | Out-Null
                }
                catch {
                    Write-Warning "Build failed, but continuing..."
                }
            }
            
            Write-Success "npm dependencies installed"
        }
        catch {
            Write-Error "npm install failed: $_"
        }
    } else {
        Write-Warning "npm not found. Some features may be limited."
        Write-Info "To install Node.js/npm, visit: https://nodejs.org/"
    }
    
    Pop-Location
} else {
    Write-Info "No package.json found in Plugin Check"
}

# Step 4: Activate Plugin Check
Write-Info "Step 4: Activating Plugin Check..."

try {
    $isActive = & wp plugin is-active plugin-check --path="$WPPath" 2>&1
    if ($LASTEXITCODE -ne 0) {
        $activateResult = & wp plugin activate plugin-check --path="$WPPath" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to activate Plugin Check: $activateResult"
            exit 1
        }
        Write-Success "Plugin Check activated"
    } else {
        Write-Success "Plugin Check already active"
    }
}
catch {
    Write-Error "Failed to activate Plugin Check: $_"
    exit 1
}

# Step 5: Verify installation
Write-Info "Step 5: Verifying Plugin Check installation..."

try {
    $helpResult = & wp plugin check --help --path="$WPPath" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Plugin Check CLI is working!"
        
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Global:colors.Green
        Write-Host "🎉 Plugin Check Setup Complete!" -ForegroundColor $Global:colors.Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Global:colors.Green
        Write-Host ""
        Write-Host "You can now use Plugin Check as a data source:" -ForegroundColor White
        Write-Host ""
        Write-Host "1. Run checks on any plugin:" -ForegroundColor White
        Write-Host "   wp plugin check <plugin-name>" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Export results in different formats:" -ForegroundColor White
        Write-Host "   wp plugin check <plugin-name> --format=json" -ForegroundColor Gray
        Write-Host "   wp plugin check <plugin-name> --format=csv" -ForegroundColor Gray
        Write-Host ""
        Write-Host "3. Run specific checks:" -ForegroundColor White
        Write-Host "   wp plugin check <plugin-name> --checks=late_escaping,i18n_usage" -ForegroundColor Gray
        Write-Host ""
        Write-Host "4. Include experimental checks:" -ForegroundColor White
        Write-Host "   wp plugin check <plugin-name> --include-experimental" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Error "Plugin Check CLI verification failed"
        Write-Host "Please check the installation manually" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Error "Plugin Check CLI verification failed: $_"
    exit 1
}

# Create integration helper script
$HelperScript = Join-Path $WPPath "wp-content\plugins\plugin-check-helper.php"

$helperContent = @'
<?php
/**
 * Plugin Check Integration Helper
 * 
 * This helper provides programmatic access to Plugin Check results
 */

if (!defined('ABSPATH')) {
    die('Direct access not allowed');
}

class Plugin_Check_Helper {
    
    /**
     * Run Plugin Check and get results as array
     */
    public static function run_check($plugin_slug, $options = []) {
        if (!class_exists('Plugin_Check')) {
            return ['error' => 'Plugin Check not found'];
        }
        
        $defaults = [
            'format' => 'json',
            'checks' => [],
            'exclude_checks' => [],
            'include_experimental' => false
        ];
        
        $options = wp_parse_args($options, $defaults);
        
        // Build command
        $command = sprintf('wp plugin check %s --format=%s', 
            escapeshellarg($plugin_slug),
            escapeshellarg($options['format'])
        );
        
        if (!empty($options['checks'])) {
            $command .= ' --checks=' . escapeshellarg(implode(',', $options['checks']));
        }
        
        if ($options['include_experimental']) {
            $command .= ' --include-experimental';
        }
        
        // Execute command
        $output = shell_exec($command . ' 2>&1');
        
        if ($options['format'] === 'json') {
            return json_decode($output, true);
        }
        
        return $output;
    }
    
    /**
     * Get Plugin Check insights
     */
    public static function get_insights($plugin_slug) {
        $results = self::run_check($plugin_slug, ['format' => 'json']);
        
        if (isset($results['error'])) {
            return $results;
        }
        
        $insights = [
            'total_checks' => 0,
            'errors' => 0,
            'warnings' => 0,
            'categories' => [],
            'critical_issues' => [],
            'recommendations' => []
        ];
        
        if (is_array($results)) {
            foreach ($results as $result) {
                $insights['total_checks']++;
                
                if ($result['type'] === 'ERROR') {
                    $insights['errors']++;
                    $insights['critical_issues'][] = [
                        'code' => $result['code'],
                        'message' => $result['message'],
                        'file' => $result['file'] ?? '',
                        'line' => $result['line'] ?? 0
                    ];
                } elseif ($result['type'] === 'WARNING') {
                    $insights['warnings']++;
                }
                
                if (!empty($result['category'])) {
                    $insights['categories'][$result['category']] = 
                        ($insights['categories'][$result['category']] ?? 0) + 1;
                }
            }
        }
        
        // Generate recommendations
        if ($insights['errors'] > 0) {
            $insights['recommendations'][] = 'Fix all ERROR-level issues before plugin submission';
        }
        
        if ($insights['warnings'] > 10) {
            $insights['recommendations'][] = 'Review and address WARNING-level issues to improve code quality';
        }
        
        return $insights;
    }
}

// Register WP-CLI command if available
if (defined('WP_CLI') && WP_CLI) {
    WP_CLI::add_command('plugin-check-insights', function($args) {
        if (empty($args[0])) {
            WP_CLI::error('Plugin slug required');
        }
        
        $insights = Plugin_Check_Helper::get_insights($args[0]);
        
        if (isset($insights['error'])) {
            WP_CLI::error($insights['error']);
        }
        
        WP_CLI::success('Plugin Check Insights:');
        WP_CLI::log('Errors: ' . $insights['errors']);
        WP_CLI::log('Warnings: ' . $insights['warnings']);
        WP_CLI::log('Categories: ' . implode(', ', array_keys($insights['categories'])));
        
        if (!empty($insights['recommendations'])) {
            WP_CLI::log("\nRecommendations:");
            foreach ($insights['recommendations'] as $rec) {
                WP_CLI::log('- ' . $rec);
            }
        }
    });
}
'@

$helperContent | Out-File $HelperScript -Encoding UTF8

Write-Success "Created helper script at: $HelperScript"

Write-Host ""
Write-Host "📚 Additional Resources:" -ForegroundColor $Global:colors.Blue
Write-Host "- Plugin Check Documentation: https://wordpress.org/plugins/plugin-check/" -ForegroundColor White
Write-Host "- WordPress Coding Standards: https://developer.wordpress.org/coding-standards/" -ForegroundColor White
Write-Host "- Plugin Review Guidelines: https://developer.wordpress.org/plugins/wordpress-org/detailed-plugin-guidelines/" -ForegroundColor White
Write-Host ""

Write-Host "🚀 PowerShell Testing Framework Integration:" -ForegroundColor $Global:colors.Cyan
Write-Host "- Run: .\test-plugin.ps1 <plugin-name> to include Plugin Check analysis" -ForegroundColor White
Write-Host "- Plugin Check runs in Phase 3, before AI analysis for better data integration" -ForegroundColor White
Write-Host ""