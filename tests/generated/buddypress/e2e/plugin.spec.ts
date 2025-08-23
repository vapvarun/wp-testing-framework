import { test, expect } from '@playwright/test';

test.describe('Buddypress E2E Tests', () => {
  const baseUrl = process.env.E2E_BASE_URL || 'http://localhost';
  
  test.beforeEach(async ({ page }) => {
    // Login as admin
    await page.goto(`${baseUrl}/wp-login.php`);
    await page.fill('#user_login', 'admin');
    await page.fill('#user_pass', 'password');
    await page.click('#wp-submit');
    await page.waitForLoadState('networkidle');
  });

  
  
  
  
  test('plugin should not break site functionality', async ({ page }) => {
    await page.goto(`${baseUrl}/`);
    await expect(page.locator('body')).toBeVisible();
    
    // Check for JavaScript errors
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') errors.push(msg.text());
    });
    
    await page.reload();
    expect(errors.length).toBe(0);
  });
});