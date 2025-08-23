import { test, expect } from '@playwright/test';

test.describe('BuddyPress Component Interactions', () => {
  const baseUrl = process.env.E2E_BASE_URL || 'http://buddynext.local';
  const username = process.env.E2E_USER || 'admin';
  const password = process.env.E2E_PASS || 'password';
  
  test.beforeEach(async ({ page }) => {
    // Login
    await page.goto(`${baseUrl}/wp-login.php`);
    await page.fill('#user_login', username);
    await page.fill('#user_pass', password);
    await page.click('#wp-submit');
    await page.waitForLoadState('networkidle');
    
    // Go to BuddyPress area
    await page.goto(baseUrl);
  });

  test('should interact with activity stream', async ({ page }) => {
    // Navigate to activity
    await page.goto(`${baseUrl}/activity`);
    await page.waitForLoadState('networkidle');
    
    // Check activity form exists
    const activityForm = page.locator('#whats-new-form').first();
    if (await activityForm.count() > 0) {
      // Try to post an activity
      await page.fill('#whats-new, [name="whats-new"]', 'Test activity from Playwright');
      
      const submitButton = page.locator('#aw-whats-new-submit').first();
      if (await submitButton.count() > 0) {
        await submitButton.click();
        await page.waitForLoadState('networkidle');
        
        // Check if activity was posted
        await expect(page.locator('.activity-content').first()).toContainText('Test activity');
      }
    }
  });

  test('should navigate member profiles', async ({ page }) => {
    // Go to members directory
    await page.goto(`${baseUrl}/members`);
    await page.waitForLoadState('networkidle');
    
    // Click on first member
    const firstMember = page.locator('.member-name a, .members-list a').first();
    if (await firstMember.isVisible()) {
      await firstMember.click();
      await page.waitForLoadState('networkidle');
      
      // Should be on a profile page
      await expect(page).toHaveURL(/.*\/members\/.+/);
      await expect(page.locator('.profile-header, #item-header')).toBeVisible();
    }
  });

  test('should use group functionality', async ({ page }) => {
    // Navigate to groups
    await page.goto(`${baseUrl}/groups`);
    await page.waitForLoadState('networkidle');
    
    // Check groups list exists
    const groupsList = page.locator('.groups-list, #groups-list');
    if (await groupsList.isVisible()) {
      // Click first group if exists
      const firstGroup = groupsList.locator('a').first();
      if (await firstGroup.isVisible()) {
        await firstGroup.click();
        await page.waitForLoadState('networkidle');
        
        // Should be on group page
        await expect(page).toHaveURL(/.*\/groups\/.+/);
      }
    }
  });
});