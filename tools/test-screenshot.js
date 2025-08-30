const { chromium } = require('playwright');

async function test() {
    console.log('Testing Playwright...');
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    
    console.log('Opening http://buddynext.local ...');
    await page.goto('http://buddynext.local', { waitUntil: 'domcontentloaded', timeout: 10000 });
    
    console.log('Taking screenshot...');
    await page.screenshot({ path: 'test-screenshot.png' });
    
    await browser.close();
    console.log('✅ Screenshot saved as test-screenshot.png');
}

test().catch(err => {
    console.error('Error:', err.message);
    process.exit(1);
});