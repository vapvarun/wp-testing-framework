#!/usr/bin/env node

/**
 * Screenshot Capture Tool using Playwright
 * Captures screenshots of WordPress plugin pages for visual testing
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function captureScreenshots() {
    // Get arguments
    const args = process.argv.slice(2);
    const pluginName = args[0] || 'plugin';
    const siteUrl = args[1] || 'http://buddynext.local';
    const username = args[2] || 'ai-tester';
    const password = args[3] || 'Test@2024!';
    
    // Setup directories
    const reportsDir = path.join(__dirname, '..', 'workspace', 'ai-reports', pluginName);
    const screenshotsDir = path.join(reportsDir, 'screenshots');
    if (!fs.existsSync(screenshotsDir)) {
        fs.mkdirSync(screenshotsDir, { recursive: true });
    }
    
    // Read discovered URLs from AI analysis
    let discoveredUrls = [];
    
    // 1. Read Custom Post Types
    const cptFile = path.join(reportsDir, 'custom-post-types.txt');
    if (fs.existsSync(cptFile)) {
        console.log('   📋 Reading discovered Custom Post Types...');
        const cptContent = fs.readFileSync(cptFile, 'utf8');
        const cpts = cptContent.split('\n').filter(line => line.trim());
        
        cpts.forEach(cpt => {
            const [name, label] = cpt.split(',');
            if (name && name !== 'post' && name !== 'page' && name !== 'attachment') {
                discoveredUrls.push({
                    url: `${siteUrl}/wp-admin/edit.php?post_type=${name}`,
                    name: `admin-${name}`,
                    description: `Admin: ${label || name}`
                });
                
                // Also try to access the archive page
                discoveredUrls.push({
                    url: `${siteUrl}/${name}/`,
                    name: `archive-${name}`,
                    description: `Archive: ${label || name}`
                });
            }
        });
    }
    
    // 2. Read Shortcodes and generate test pages
    const shortcodesFile = path.join(reportsDir, 'shortcodes.txt');
    if (fs.existsSync(shortcodesFile)) {
        console.log('   📋 Reading discovered Shortcodes...');
        const shortcodes = fs.readFileSync(shortcodesFile, 'utf8')
            .split('\n')
            .filter(line => line.includes('[') && line.includes(']'));
        
        // We'll need to create test pages with these shortcodes
        // For now, just document them
        if (shortcodes.length > 0) {
            fs.writeFileSync(
                path.join(reportsDir, 'shortcodes-to-test.txt'),
                shortcodes.join('\n')
            );
        }
    }
    
    // 3. Read AJAX handlers
    const ajaxFile = path.join(reportsDir, 'ajax-handlers.txt');
    const ajaxHandlers = [];
    if (fs.existsSync(ajaxFile)) {
        console.log('   📋 Reading AJAX handlers...');
        const handlers = fs.readFileSync(ajaxFile, 'utf8')
            .split('\n')
            .filter(line => line.trim());
        ajaxHandlers.push(...handlers);
    }
    
    // 4. Read tested URLs from Phase 11
    const testedUrlsFile = path.join(reportsDir, 'tested-urls.txt');
    if (fs.existsSync(testedUrlsFile)) {
        console.log('   📋 Reading URLs from test phase...');
        const urls = fs.readFileSync(testedUrlsFile, 'utf8')
            .split('\n')
            .filter(url => url.trim());
        
        urls.forEach(url => {
            const name = url.replace(siteUrl, '')
                .replace(/[^a-zA-Z0-9]/g, '_')
                .replace(/_+/g, '_')
                .toLowerCase();
            
            if (!discoveredUrls.find(u => u.url === url)) {
                discoveredUrls.push({
                    url: url,
                    name: name || 'page',
                    description: `Page: ${url}`
                });
            }
        });
    }
    
    console.log(`📸 Starting screenshot capture for ${pluginName}`);
    console.log(`   Site: ${siteUrl}`);
    console.log(`   Output: ${screenshotsDir}`);
    
    // Launch browser
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
        // Login to WordPress
        console.log('   🔐 Logging into WordPress...');
        await page.goto(`${siteUrl}/wp-login.php`);
        await page.fill('#user_login', username);
        await page.fill('#user_pass', password);
        await page.click('#wp-submit');
        await page.waitForURL('**/wp-admin/**', { timeout: 10000 }).catch(() => {
            console.log('   ⚠️ Login might have failed, continuing anyway...');
        });
        
        // Merge discovered URLs with default URLs
        let urls = [
            { url: siteUrl, name: 'homepage', description: 'Homepage' },
            { url: `${siteUrl}/wp-admin/`, name: 'admin-dashboard', description: 'Admin Dashboard' },
            { url: `${siteUrl}/wp-admin/plugins.php`, name: 'plugins-page', description: 'Plugins Page' }
        ];
        
        // Add all discovered URLs
        urls.push(...discoveredUrls);
        
        // Remove duplicates
        const uniqueUrls = [];
        const seenUrls = new Set();
        for (const item of urls) {
            if (!seenUrls.has(item.url)) {
                seenUrls.add(item.url);
                uniqueUrls.push(item);
            }
        }
        urls = uniqueUrls;
        
        console.log(`   Found ${urls.length} URLs to capture`);
        
        // Create test pages with shortcodes if needed
        if (fs.existsSync(path.join(reportsDir, 'shortcodes.txt'))) {
            console.log('   Creating test pages with shortcodes...');
            
            // Navigate to create new page
            await page.goto(`${siteUrl}/wp-admin/post-new.php?post_type=page`);
            
            const shortcodes = fs.readFileSync(path.join(reportsDir, 'shortcodes.txt'), 'utf8')
                .split('\n')
                .filter(line => line.trim() && line.includes('['));
            
            for (let i = 0; i < Math.min(shortcodes.length, 3); i++) {
                const shortcode = shortcodes[i].match(/\[([^\]]+)\]/)?.[0];
                if (!shortcode) continue;
                
                try {
                    // Create a test page with the shortcode
                    await page.goto(`${siteUrl}/wp-admin/post-new.php?post_type=page`);
                    await page.fill('input[name="post_title"]', `Test Shortcode: ${shortcode}`);
                    
                    // Switch to text mode and add shortcode
                    await page.click('#content-html').catch(() => {});
                    await page.fill('#content', shortcode);
                    
                    // Publish the page
                    await page.click('#publish');
                    await page.waitForTimeout(2000);
                    
                    // Get the page URL
                    const viewLink = await page.$eval('.updated a', el => el.href).catch(() => null);
                    if (viewLink) {
                        urls.push({
                            url: viewLink,
                            name: `shortcode-${shortcode.replace(/[\[\]]/g, '')}`,
                            description: `Shortcode Test: ${shortcode}`
                        });
                    }
                } catch (err) {
                    console.log(`   ⚠️ Could not create test page for ${shortcode}`);
                }
            }
        }
        
        // Capture screenshots
        let capturedCount = 0;
        for (const item of urls) {
            try {
                console.log(`   📸 Capturing: ${item.name} (${item.url})`);
                await page.goto(item.url, { waitUntil: 'networkidle', timeout: 30000 });
                
                // Wait a bit for any dynamic content
                await page.waitForTimeout(2000);
                
                // Capture full page screenshot
                await page.screenshot({
                    path: path.join(screenshotsDir, `${item.name}.png`),
                    fullPage: true
                });
                
                // Also capture above-the-fold screenshot
                await page.screenshot({
                    path: path.join(screenshotsDir, `${item.name}-viewport.png`),
                    fullPage: false
                });
                
                capturedCount++;
            } catch (error) {
                console.log(`   ⚠️ Failed to capture ${item.name}: ${error.message}`);
            }
        }
        
        // Capture mobile versions
        console.log('   📱 Capturing mobile versions...');
        await context.close();
        
        const mobileContext = await browser.newContext({
            viewport: { width: 375, height: 812 }, // iPhone X
            userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1',
            ignoreHTTPSErrors: true
        });
        
        const mobilePage = await mobileContext.newPage();
        
        // Login on mobile
        await mobilePage.goto(`${siteUrl}/wp-login.php`);
        await mobilePage.fill('#user_login', username);
        await mobilePage.fill('#user_pass', password);
        await mobilePage.click('#wp-submit');
        await mobilePage.waitForTimeout(2000);
        
        // Capture key mobile pages
        const mobileUrls = [
            { url: siteUrl, name: 'mobile-homepage' },
            { url: `${siteUrl}/forums/`, name: 'mobile-forums' }
        ];
        
        for (const item of mobileUrls) {
            try {
                console.log(`   📱 Mobile: ${item.name}`);
                await mobilePage.goto(item.url, { waitUntil: 'networkidle', timeout: 30000 });
                await mobilePage.waitForTimeout(2000);
                await mobilePage.screenshot({
                    path: path.join(screenshotsDir, `${item.name}.png`),
                    fullPage: true
                });
            } catch (error) {
                console.log(`   ⚠️ Failed mobile capture: ${item.name}`);
            }
        }
        
        console.log(`   ✅ Captured ${capturedCount} screenshots successfully!`);
        
        // Generate visual analysis report
        const report = `# 🎨 Visual Analysis Report

Generated: ${new Date().toISOString()}
Plugin: ${pluginName}
Site: ${siteUrl}

## 📸 Screenshots Captured

### Desktop Views (1920x1080)
${urls.map(item => `- [${item.name}](screenshots/${item.name}.png)`).join('\n')}

### Mobile Views (375x812)
${mobileUrls.map(item => `- [${item.name}](screenshots/${item.name}.png)`).join('\n')}

## 🔍 Visual Testing Checklist

### Layout & Design
- [ ] Responsive design works on mobile
- [ ] No horizontal scrolling on mobile
- [ ] Buttons are large enough for touch
- [ ] Text is readable without zooming
- [ ] Images scale properly

### User Interface
- [ ] Navigation is intuitive
- [ ] Forms are easy to fill
- [ ] Error messages are clear
- [ ] Success messages are visible
- [ ] Loading states are shown

### Accessibility
- [ ] Sufficient color contrast
- [ ] Focus indicators visible
- [ ] Alt text for images
- [ ] Keyboard navigation works
- [ ] Screen reader compatible

### Performance
- [ ] No layout shifts during load
- [ ] Images are optimized
- [ ] Fonts load properly
- [ ] No JavaScript errors in console
- [ ] Page loads under 3 seconds

## 📊 Recommendations

Based on the screenshots captured, consider:

1. **Mobile Optimization**: Ensure all features work on mobile devices
2. **Performance**: Optimize images and reduce load times
3. **Accessibility**: Add ARIA labels and improve contrast
4. **User Experience**: Simplify complex forms and workflows
5. **Visual Consistency**: Maintain consistent styling across pages
`;
        
        fs.writeFileSync(
            path.join(screenshotsDir, '..', 'VISUAL-ANALYSIS.md'),
            report
        );
        
        console.log('   📝 Visual analysis report generated!');
        
    } catch (error) {
        console.error('Error during screenshot capture:', error);
    } finally {
        await browser.close();
    }
}

// Run the capture
captureScreenshots().catch(console.error);