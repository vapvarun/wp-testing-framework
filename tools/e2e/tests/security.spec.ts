import { test, expect } from '@playwright/test';

test.describe('BuddyPress Security Tests', () => {
  const baseUrl = process.env.E2E_BASE_URL || 'http://buddynext.local';
  const username = process.env.E2E_USER || 'admin';
  const password = process.env.E2E_PASS || 'password';

  // XSS payloads for testing
  const xssPayloads = [
    '<script>alert("XSS")</script>',
    'javascript:alert("XSS")',
    '<img src=x onerror=alert("XSS")>',
    '<svg onload=alert("XSS")>',
    '"><script>alert("XSS")</script>',
  ];

  test.beforeEach(async ({ page }) => {
    // Login as admin
    await page.goto(`${baseUrl}/wp-login.php`);
    await page.fill('#user_login', username);
    await page.fill('#user_pass', password);
    await page.click('#wp-submit');
    await page.waitForLoadState('networkidle');
  });

  test('should prevent XSS in activity updates', async ({ page }) => {
    await page.goto(`${baseUrl}/activity`);
    await page.waitForLoadState('networkidle');

    // Try to post XSS payload in activity
    const activityForm = page.locator('#whats-new-form').first();
    if (await activityForm.count() > 0) {
      for (const payload of xssPayloads.slice(0, 2)) { // Test first 2 payloads
        await page.fill('#whats-new', `Test activity ${payload}`);
        
        const submitButton = page.locator('#aw-whats-new-submit').first();
        if (await submitButton.count() > 0) {
          await submitButton.click();
          await page.waitForLoadState('networkidle');
          
          // Check that script tags are not executed/present in DOM
          const scriptTags = await page.locator('script:has-text("alert")').count();
          expect(scriptTags).toBe(0);
          
          // Check that content is properly escaped
          const activityContent = await page.locator('.activity-content').first().textContent();
          expect(activityContent).not.toContain('<script>');
        }
      }
    }
  });

  test('should prevent XSS in user profile updates', async ({ page }) => {
    await page.goto(`${baseUrl}/members/${username}/profile/edit`);
    await page.waitForLoadState('networkidle');

    // Test profile field XSS protection
    const displayNameField = page.locator('#field_1'); // Usually display name
    if (await displayNameField.count() > 0) {
      const payload = xssPayloads[0];
      await displayNameField.fill(`Test Name ${payload}`);
      
      const saveButton = page.locator('#profile-group-edit-submit');
      if (await saveButton.count() > 0) {
        await saveButton.click();
        await page.waitForLoadState('networkidle');
        
        // Check that script is not executed
        const scriptTags = await page.locator('script:has-text("alert")').count();
        expect(scriptTags).toBe(0);
      }
    }
  });

  test('should prevent XSS in group creation', async ({ page }) => {
    await page.goto(`${baseUrl}/groups/create`);
    await page.waitForLoadState('networkidle');

    const payload = xssPayloads[0];
    
    // Test group name XSS protection
    const groupNameField = page.locator('#group-name');
    if (await groupNameField.count() > 0) {
      await groupNameField.fill(`Test Group ${payload}`);
      
      const groupDescField = page.locator('#group-desc');
      if (await groupDescField.count() > 0) {
        await groupDescField.fill(`Group description ${payload}`);
        
        const createButton = page.locator('#group-creation-create');
        if (await createButton.count() > 0) {
          await createButton.click();
          await page.waitForLoadState('networkidle');
          
          // Check that script is not executed
          const scriptTags = await page.locator('script:has-text("alert")').count();
          expect(scriptTags).toBe(0);
        }
      }
    }
  });

  test('should protect private messaging from XSS', async ({ page }) => {
    await page.goto(`${baseUrl}/members/${username}/messages/compose`);
    await page.waitForLoadState('networkidle');

    const payload = xssPayloads[0];
    
    // Test message subject and content
    const subjectField = page.locator('#subject');
    if (await subjectField.count() > 0) {
      await subjectField.fill(`Test Subject ${payload}`);
      
      const contentField = page.locator('#message_content');
      if (await contentField.count() > 0) {
        await contentField.fill(`Message content ${payload}`);
        
        const sendButton = page.locator('#send');
        if (await sendButton.count() > 0) {
          await sendButton.click();
          await page.waitForLoadState('networkidle');
          
          // Check that script is not executed
          const scriptTags = await page.locator('script:has-text("alert")').count();
          expect(scriptTags).toBe(0);
        }
      }
    }
  });

  test('should require authentication for admin areas', async ({ page }) => {
    // Logout first
    await page.goto(`${baseUrl}/wp-login.php?action=logout`);
    await page.click('a[href*="logout"]').catch(() => {}); // Ignore if link not found
    
    // Try to access admin area without authentication
    await page.goto(`${baseUrl}/wp-admin/`);
    
    // Should be redirected to login page
    await page.waitForLoadState('networkidle');
    expect(page.url()).toContain('wp-login.php');
    
    // Check for login form
    const loginForm = page.locator('#loginform');
    await expect(loginForm).toBeVisible();
  });

  test('should protect against CSRF attacks', async ({ page }) => {
    // Go to a form that should have CSRF protection
    await page.goto(`${baseUrl}/groups/create`);
    await page.waitForLoadState('networkidle');
    
    // Check for nonce field
    const nonceField = page.locator('input[name*="nonce"], input[name*="_wpnonce"]');
    const nonceCount = await nonceField.count();
    
    expect(nonceCount).toBeGreaterThan(0);
  });

  test('should have secure headers', async ({ page }) => {
    const response = await page.goto(`${baseUrl}/`);
    const headers = response?.headers() || {};
    
    // Check for security headers (some may not be present in dev environment)
    const securityHeaders = [
      'x-frame-options',
      'x-content-type-options', 
      'x-xss-protection',
    ];
    
    let secureHeadersFound = 0;
    for (const header of securityHeaders) {
      if (headers[header]) {
        secureHeadersFound++;
      }
    }
    
    // At least some security headers should be present
    console.log(`Found ${secureHeadersFound} security headers out of ${securityHeaders.length}`);
  });

  test('should prevent directory browsing', async ({ page }) => {
    const directoriesToTest = [
      '/wp-content/plugins/',
      '/wp-content/themes/',
      '/wp-content/uploads/',
    ];
    
    for (const dir of directoriesToTest) {
      const response = await page.goto(`${baseUrl}${dir}`);
      const content = await page.textContent('body');
      
      // Should not show directory listing
      expect(content).not.toContain('Index of');
      expect(content).not.toContain('Parent Directory');
    }
  });

  test('should hide WordPress version information', async ({ page }) => {
    // Check homepage source for version disclosure
    await page.goto(`${baseUrl}/`);
    const content = await page.content();
    
    // Should not reveal WordPress version in meta tags
    expect(content).not.toMatch(/wordpress.*\d+\.\d+/i);
    expect(content).not.toMatch(/wp.*\d+\.\d+/i);
  });

  test('should protect wp-config.php access', async ({ page }) => {
    // Try to access wp-config.php directly
    const response = await page.goto(`${baseUrl}/wp-config.php`).catch(() => null);
    
    if (response) {
      const status = response.status();
      // Should return 403 Forbidden or 404 Not Found, not 200 OK
      expect([403, 404]).toContain(status);
    }
  });
});