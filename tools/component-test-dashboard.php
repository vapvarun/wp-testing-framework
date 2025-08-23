#!/usr/bin/env php
<?php
/**
 * BuddyPress Component Testing Dashboard
 * Shows testing progress for each component
 */

// Colors for terminal output
class Colors {
    const RED = "\033[0;31m";
    const GREEN = "\033[0;32m";
    const YELLOW = "\033[1;33m";
    const BLUE = "\033[0;34m";
    const MAGENTA = "\033[0;35m";
    const CYAN = "\033[0;36m";
    const WHITE = "\033[1;37m";
    const NC = "\033[0m"; // No Color
}

// Component configuration
$components = [
    'core' => [
        'name' => 'Core',
        'priority' => 'Critical',
        'unit_tests' => 15,
        'integration_tests' => 10,
        'e2e_tests' => 0,
    ],
    'members' => [
        'name' => 'Members',
        'priority' => 'Critical',
        'unit_tests' => 25,
        'integration_tests' => 15,
        'e2e_tests' => 10,
    ],
    'xprofile' => [
        'name' => 'Extended Profiles',
        'priority' => 'High',
        'unit_tests' => 20,
        'integration_tests' => 12,
        'e2e_tests' => 8,
    ],
    'activity' => [
        'name' => 'Activity Streams',
        'priority' => 'High',
        'unit_tests' => 30,
        'integration_tests' => 20,
        'e2e_tests' => 15,
    ],
    'groups' => [
        'name' => 'Groups',
        'priority' => 'High',
        'unit_tests' => 35,
        'integration_tests' => 25,
        'e2e_tests' => 20,
    ],
    'friends' => [
        'name' => 'Friends',
        'priority' => 'Medium',
        'unit_tests' => 15,
        'integration_tests' => 10,
        'e2e_tests' => 5,
    ],
    'messages' => [
        'name' => 'Messages',
        'priority' => 'Medium',
        'unit_tests' => 20,
        'integration_tests' => 15,
        'e2e_tests' => 10,
    ],
    'notifications' => [
        'name' => 'Notifications',
        'priority' => 'Medium',
        'unit_tests' => 15,
        'integration_tests' => 10,
        'e2e_tests' => 5,
    ],
    'settings' => [
        'name' => 'Settings',
        'priority' => 'Low',
        'unit_tests' => 10,
        'integration_tests' => 8,
        'e2e_tests' => 5,
    ],
    'blogs' => [
        'name' => 'Site Tracking',
        'priority' => 'Low',
        'unit_tests' => 10,
        'integration_tests' => 8,
        'e2e_tests' => 0,
    ],
];

// Function to count actual test files
function countTestFiles($component, $type) {
    $base_path = __DIR__ . '/../tests/phpunit/Components/';
    $component_name = ucfirst($component);
    if ($component === 'xprofile') {
        $component_name = 'XProfile';
    }
    
    $path = $base_path . $component_name . '/' . ucfirst($type) . '/';
    
    if (!is_dir($path)) {
        return 0;
    }
    
    $files = glob($path . '*Test.php');
    return count($files);
}

// Function to get priority color
function getPriorityColor($priority) {
    switch($priority) {
        case 'Critical':
            return Colors::RED;
        case 'High':
            return Colors::YELLOW;
        case 'Medium':
            return Colors::BLUE;
        case 'Low':
            return Colors::CYAN;
        default:
            return Colors::WHITE;
    }
}

// Function to calculate progress
function calculateProgress($actual, $total) {
    if ($total == 0) return 100;
    return round(($actual / $total) * 100);
}

// Function to draw progress bar
function drawProgressBar($percentage, $width = 20) {
    $filled = round($width * $percentage / 100);
    $empty = $width - $filled;
    
    $bar = '[';
    $bar .= str_repeat('█', $filled);
    $bar .= str_repeat('░', $empty);
    $bar .= ']';
    
    if ($percentage == 100) {
        return Colors::GREEN . $bar . Colors::NC;
    } elseif ($percentage >= 50) {
        return Colors::YELLOW . $bar . Colors::NC;
    } else {
        return Colors::RED . $bar . Colors::NC;
    }
}

// Clear screen
system('clear');

// Display header
echo Colors::BLUE . "╔══════════════════════════════════════════════════════════════════════════════╗\n";
echo "║                    BuddyPress Component Testing Dashboard                       ║\n";
echo "╚══════════════════════════════════════════════════════════════════════════════╝" . Colors::NC . "\n\n";

// Display component status
echo Colors::WHITE . "Component Testing Status:\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" . Colors::NC;

$totalTests = 0;
$completedTests = 0;

foreach ($components as $id => $component) {
    $unitActual = countTestFiles($id, 'unit');
    $integrationActual = countTestFiles($id, 'integration');
    $e2eActual = 0; // E2E tests are in different location
    
    $unitTotal = $component['unit_tests'];
    $integrationTotal = $component['integration_tests'];
    $e2eTotal = $component['e2e_tests'];
    
    $componentTotal = $unitTotal + $integrationTotal + $e2eTotal;
    $componentActual = $unitActual + $integrationActual + $e2eActual;
    
    $totalTests += $componentTotal;
    $completedTests += $componentActual;
    
    $progress = calculateProgress($componentActual, $componentTotal);
    
    // Component name with priority
    $priorityColor = getPriorityColor($component['priority']);
    echo sprintf("%-20s", $component['name']);
    echo $priorityColor . sprintf("[%-8s]", $component['priority']) . Colors::NC . " ";
    
    // Progress bar
    echo drawProgressBar($progress) . " ";
    
    // Stats
    echo sprintf("%3d%%", $progress) . " ";
    echo sprintf("(%d/%d)", $componentActual, $componentTotal) . "\n";
    
    // Test type breakdown
    echo "  └─ Unit: " . sprintf("%2d/%-2d", $unitActual, $unitTotal);
    echo " │ Integration: " . sprintf("%2d/%-2d", $integrationActual, $integrationTotal);
    echo " │ E2E: " . sprintf("%2d/%-2d", $e2eActual, $e2eTotal) . "\n\n";
}

// Display summary
echo Colors::WHITE . "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "Overall Progress: " . Colors::NC;

$overallProgress = calculateProgress($completedTests, $totalTests);
echo drawProgressBar($overallProgress, 30) . " ";
echo sprintf("%3d%%", $overallProgress) . " ";
echo sprintf("(%d/%d tests)", $completedTests, $totalTests) . "\n\n";

// Display legend
echo Colors::WHITE . "Legend:\n" . Colors::NC;
echo Colors::RED . "■" . Colors::NC . " Critical  ";
echo Colors::YELLOW . "■" . Colors::NC . " High  ";
echo Colors::BLUE . "■" . Colors::NC . " Medium  ";
echo Colors::CYAN . "■" . Colors::NC . " Low\n\n";

// Display available commands
echo Colors::WHITE . "Quick Commands:\n" . Colors::NC;
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "Test specific component:  " . Colors::CYAN . "npm run test:bp:members" . Colors::NC . "\n";
echo "Test component group:     " . Colors::CYAN . "npm run test:bp:critical" . Colors::NC . "\n";
echo "Generate coverage:        " . Colors::CYAN . "npm run coverage:bp:activity" . Colors::NC . "\n";
echo "Run all tests:           " . Colors::CYAN . "npm run test:bp:all" . Colors::NC . "\n";
echo "\n";

// Display next steps
if ($overallProgress < 100) {
    echo Colors::YELLOW . "📝 Next Steps:\n" . Colors::NC;
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    
    $priorityOrder = ['Critical', 'High', 'Medium', 'Low'];
    $shown = 0;
    
    foreach ($priorityOrder as $priority) {
        foreach ($components as $id => $component) {
            if ($component['priority'] === $priority && $shown < 3) {
                $componentActual = countTestFiles($id, 'unit') + countTestFiles($id, 'integration');
                $componentTotal = $component['unit_tests'] + $component['integration_tests'];
                
                if ($componentActual < $componentTotal) {
                    echo "• Complete " . $component['name'] . " tests ";
                    echo "(" . ($componentTotal - $componentActual) . " remaining)\n";
                    $shown++;
                }
            }
        }
    }
} else {
    echo Colors::GREEN . "🎉 All tests completed! Great job!\n" . Colors::NC;
}

echo "\n";