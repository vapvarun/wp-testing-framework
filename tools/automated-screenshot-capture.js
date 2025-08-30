#!/usr/bin/env node

/**
 * Automated Screenshot Capture for WordPress Test Data
 * Captures screenshots of all generated test data pages
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function captureAutomatedScreenshots() {
    const args = process.argv.slice(2);
    const pluginName = args[0] || 'bbpress';
    const siteUrl = args[1] || 'http://wptesting.local';
    const username = args[2] || 'admin';
    const password = args[3] || 'Test@2024!';
    
    // Check if we should use auto-login
    const useAutoLogin = process.env.USE_AUTO_LOGIN === 'true' || args.includes('--auto-login');
    
    // Setup directories
    const scanDir = path.join(__dirname, '..', '..', 'wp-content', 'uploads', 'wbcom-scan', pluginName);
    const latestScan = fs.readdirSync(scanDir).sort().pop();
    const screenshotsDir = path.join(scanDir, latestScan, 'screenshots');
    
    if (!fs.existsSync(screenshotsDir)) {
        fs.mkdirSync(screenshotsDir, { recursive: true });
    }
    
    // Read AI-generated URL plan
    const urlPlanFile = path.join(scanDir, latestScan, 'reports', 'screenshot-urls.json');
    let urlPlan = null;
    
    if (fs.existsSync(urlPlanFile)) {
        urlPlan = JSON.parse(fs.readFileSync(urlPlanFile, 'utf8'));
        console.log(`   📋 Loaded AI-generated URL plan with ${urlPlan.urls.length} URLs`);
    }
    
    // Fallback to test data plan if no URL plan
    const testDataPlanFile = path.join(scanDir, latestScan, 'reports', 'test-data-plan.json');
    let testDataPlan = { test_data: [] };
    
    if (!urlPlan && fs.existsSync(testDataPlanFile)) {
        testDataPlan = JSON.parse(fs.readFileSync(testDataPlanFile, 'utf8'));
    }
    
    console.log(`📸 Starting automated screenshot capture for ${pluginName}`);
    console.log(`   Site: ${siteUrl}`);
    console.log(`   Output: ${screenshotsDir}`);
    
    // Launch browser in interactive mode if requested
    const isInteractive = process.env.INTERACTIVE === 'true' || args.includes('--interactive');
    
    const browser = await chromium.launch({
        headless: !isInteractive,
        slowMo: isInteractive ? 500 : 0, // Slow down actions so you can see them
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    if (isInteractive) {
        console.log('   👁️  Running in INTERACTIVE mode - you can watch the browser!');
        console.log('   ⏸️  Actions are slowed down for visibility');
    }
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true,
        recordVideo: isInteractive ? { dir: path.join(screenshotsDir, 'videos') } : undefined
    });
    
    const page = await context.newPage();
    
    try {
        // Login to WordPress
        if (useAutoLogin) {
            console.log('   🔐 Generating auto-login URL...');
            
            // Generate auto-login URL using PHP script
            const { execSync } = require('child_process');
            const autoLoginUrl = execSync(
                `cd "${path.join(__dirname, '..')}" && php tools/create-auto-login.php ${username} 30`,
                { encoding: 'utf8' }
            ).trim().split('\n').pop();
            
            if (autoLoginUrl && autoLoginUrl.includes('auto_login')) {
                console.log('   ✅ Auto-login URL generated');
                console.log('   🚀 Logging in automatically...');
                await page.goto(autoLoginUrl);
                await page.waitForURL('**/wp-admin/**', { timeout: 10000 });
                console.log('   ✅ Logged in successfully!');
            } else {
                console.log('   ⚠️ Could not generate auto-login URL, falling back to manual login');
                await manualLogin();
            }
        } else {
            await manualLogin();
        }
        
        async function manualLogin() {
            console.log('   🔐 Logging into WordPress...');
            if (isInteractive) {
                console.log('   👀 Watch the login process...');
            }
            await page.goto(`${siteUrl}/wp-login.php`);
            await page.fill('#user_login', username);
            await page.fill('#user_pass', password);
            await page.click('#wp-submit');
            await page.waitForURL('**/wp-admin/**', { timeout: 10000 }).catch(() => {
                console.log('   ⚠️ Login might have failed, continuing anyway...');
            });
        }
        
        // Use AI-generated URLs if available
        if (urlPlan && urlPlan.urls) {
            console.log(`\n   🤖 Using AI-determined URLs for screenshot capture...`);
            console.log(`   📊 Categories: ${[...new Set(urlPlan.urls.map(u => u.category))].join(', ')}\n`);
            
            for (const urlInfo of urlPlan.urls) {
                console.log(`   📸 [${urlInfo.category}] ${urlInfo.description}`);
                if (isInteractive) {
                    console.log(`   👉 URL: ${urlInfo.url}`);
                    console.log(`   ⏱️ Wait time: ${urlInfo.waitTime || 2000}ms`);
                }
                
                try {
                    await page.goto(urlInfo.url, { waitUntil: 'networkidle', timeout: 15000 });
                    
                    // Wait for specific selector if provided
                    if (urlInfo.waitForSelector) {
                        await page.waitForSelector(urlInfo.waitForSelector, { timeout: 5000 }).catch(() => {});
                    }
                    
                    await page.waitForTimeout(urlInfo.waitTime || 2000);
                    
                    // Take screenshot
                    await page.screenshot({
                        path: path.join(screenshotsDir, `${urlInfo.name}.png`),
                        fullPage: true
                    });
                    
                    // Also capture viewport screenshot for important pages
                    if (urlInfo.priority <= 2) {
                        await page.screenshot({
                            path: path.join(screenshotsDir, `${urlInfo.name}-viewport.png`),
                            fullPage: false
                        });
                    }
                    
                    console.log(`   ✅ Captured: ${urlInfo.name}`);
                } catch (err) {
                    console.log(`   ⚠️ Failed to capture ${urlInfo.name}: ${err.message}`);
                }
            }
            
            // Skip the old manual URL capture if we used AI URLs
            return;
        }
        
        // Fallback to old method if no AI URL plan
        console.log(`\n   ℹ️ No AI URL plan found, using fallback method...\n`);
        
        // Capture admin pages for custom post types
        const customPostTypes = testDataPlan.test_data.filter(item => item.type === 'custom_post_type');
        const uniqueCPTs = [...new Set(customPostTypes.map(cpt => cpt.name))];
        
        for (const cptName of uniqueCPTs) {
            console.log(`   📸 Capturing admin page for ${cptName}...`);
            if (isInteractive) {
                console.log(`   👉 Navigating to: ${siteUrl}/wp-admin/edit.php?post_type=${cptName}`);
            }
            await page.goto(`${siteUrl}/wp-admin/edit.php?post_type=${cptName}`, { waitUntil: 'networkidle' });
            await page.waitForTimeout(isInteractive ? 2000 : 1000);
            await page.screenshot({
                path: path.join(screenshotsDir, `admin-${cptName}.png`),
                fullPage: true
            });
        }
        
        // Capture shortcode test pages
        const shortcodePages = testDataPlan.test_data.filter(item => item.type === 'shortcode');
        
        for (const shortcodePage of shortcodePages) {
            const pageName = shortcodePage.name.replace(/[\[\]]/g, '');
            const pageSlug = shortcodePage.data.post_title.toLowerCase()
                .replace(/\[|\]/g, '')
                .replace(/\s+/g, '-')
                .replace(/:/g, '');
            
            console.log(`   📸 Capturing shortcode page: ${pageName}...`);
            
            // Try the URL based on the title
            const pageUrl = `${siteUrl}/${pageSlug}/`;
            
            try {
                if (isInteractive) {
                    console.log(`   👉 Navigating to: ${pageUrl}`);
                }
                await page.goto(pageUrl, { waitUntil: 'networkidle', timeout: 10000 });
                await page.waitForTimeout(isInteractive ? 2000 : 1000);
                await page.screenshot({
                    path: path.join(screenshotsDir, `shortcode-${pageName}.png`),
                    fullPage: true
                });
            } catch (err) {
                console.log(`   ⚠️ Could not capture ${pageName}: ${err.message}`);
            }
        }
        
        // Capture frontend forum/topic/reply pages
        if (pluginName.toLowerCase() === 'bbpress') {
            // Capture forums index
            console.log('   📸 Capturing BBPress forums index...');
            await page.goto(`${siteUrl}/forums/`, { waitUntil: 'networkidle' }).catch(() => {});
            await page.waitForTimeout(1000);
            await page.screenshot({
                path: path.join(screenshotsDir, 'bbpress-forums-index.png'),
                fullPage: true
            });
            
            // Get first forum and capture it
            const firstForum = await page.$('.bbp-forum-title a');
            if (firstForum) {
                const forumUrl = await firstForum.getAttribute('href');
                console.log('   📸 Capturing sample forum page...');
                await page.goto(forumUrl, { waitUntil: 'networkidle' });
                await page.waitForTimeout(1000);
                await page.screenshot({
                    path: path.join(screenshotsDir, 'bbpress-forum-single.png'),
                    fullPage: true
                });
                
                // Get first topic in the forum
                const firstTopic = await page.$('.bbp-topic-title a');
                if (firstTopic) {
                    const topicUrl = await firstTopic.getAttribute('href');
                    console.log('   📸 Capturing sample topic page...');
                    await page.goto(topicUrl, { waitUntil: 'networkidle' });
                    await page.waitForTimeout(1000);
                    await page.screenshot({
                        path: path.join(screenshotsDir, 'bbpress-topic-single.png'),
                        fullPage: true
                    });
                }
            }
        }
        
        // Capture dashboard
        console.log('   📸 Capturing WordPress dashboard...');
        await page.goto(`${siteUrl}/wp-admin/`, { waitUntil: 'networkidle' });
        await page.waitForTimeout(1000);
        await page.screenshot({
            path: path.join(screenshotsDir, 'wordpress-dashboard.png'),
            fullPage: true
        });
        
        // Count screenshots
        const screenshots = fs.readdirSync(screenshotsDir).filter(f => f.endsWith('.png'));
        console.log(`\n   ✅ Captured ${screenshots.length} screenshots successfully!`);
        
        // Group screenshots by type
        const screenshotGroups = {};
        screenshots.forEach(file => {
            const prefix = file.split('-')[0];
            screenshotGroups[prefix] = (screenshotGroups[prefix] || 0) + 1;
        });
        
        console.log(`   📊 Screenshot breakdown:`);
        Object.entries(screenshotGroups).forEach(([group, count]) => {
            console.log(`      - ${group}: ${count}`);
        });
        
        // Save screenshot list with metadata
        const screenshotMetadata = {
            total: screenshots.length,
            groups: screenshotGroups,
            files: screenshots,
            capturedAt: new Date().toISOString(),
            mode: isInteractive ? 'interactive' : 'headless'
        };
        
        fs.writeFileSync(
            path.join(screenshotsDir, 'screenshot-metadata.json'),
            JSON.stringify(screenshotMetadata, null, 2)
        );
        
    } catch (error) {
        console.error('   ❌ Error during screenshot capture:', error.message);
    } finally {
        await browser.close();
    }
}

// Run the capture
captureAutomatedScreenshots().catch(console.error);