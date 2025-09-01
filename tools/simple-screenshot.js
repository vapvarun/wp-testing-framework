#!/usr/bin/env node

/**
 * Simple Screenshot Capture for specific URLs
 * Usage: node simple-screenshot.js <url> <output-file> [username] [password]
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function captureScreenshot() {
    const args = process.argv.slice(2);
    const url = args[0];
    const outputFile = args[1];
    const username = args[2] || 'admin';
    const password = args[3] || '';
    
    if (!url || !outputFile) {
        console.error('Usage: node simple-screenshot.js <url> <output-file> [username] [password]');
        process.exit(1);
    }
    
    // Ensure output directory exists
    const outputDir = path.dirname(outputFile);
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }
    
    const browser = await chromium.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true
    });
    
    const page = await context.newPage();
    
    try {
        // Check if we need to use auto-login
        const useAutoLogin = process.env.USE_AUTO_LOGIN === 'true';
        
        if (useAutoLogin && url.includes('.local')) {
            // Generate auto-login URL
            const { execSync } = require('child_process');
            const frameworkPath = path.join(__dirname, '..');
            
            try {
                const autoLoginUrl = execSync(
                    `cd "${frameworkPath}" && php tools/create-auto-login.php ${username} 5`,
                    { encoding: 'utf8' }
                ).trim().split('\n').pop();
                
                if (autoLoginUrl && autoLoginUrl.includes('auto_login')) {
                    // Navigate to auto-login URL first
                    await page.goto(autoLoginUrl, { waitUntil: 'networkidle', timeout: 15000 });
                    // Wait for redirect to admin
                    await page.waitForTimeout(2000);
                }
            } catch (e) {
                // Auto-login failed, continue without it
            }
        }
        
        // Navigate to the actual URL
        await page.goto(url, { waitUntil: 'networkidle', timeout: 15000 });
        await page.waitForTimeout(2000);
        
        // Take screenshot
        await page.screenshot({
            path: outputFile,
            fullPage: true
        });
        
        console.log(`✅ Captured: ${outputFile}`);
        
    } catch (error) {
        console.error(`❌ Failed to capture ${url}: ${error.message}`);
    } finally {
        await browser.close();
    }
}

captureScreenshot().catch(console.error);