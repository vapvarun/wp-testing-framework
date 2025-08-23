import { test, expect } from '@playwright/test';
const USER = process.env.E2E_USER || 'admin';
const PASS = process.env.E2E_PASS || 'password';
test('wp-admin loads and dashboard renders', async ({ page }) => {
  await page.goto('/wp-login.php');
  await page.fill('#user_login', USER);
  await page.fill('#user_pass', PASS);
  await page.click('#wp-submit');
  await page.waitForLoadState('networkidle');
  await page.goto('/wp-admin/index.php');
  await expect(page.locator('#wpbody-content')).toBeVisible();
  await expect(page).toHaveScreenshot('dashboard.png');
});
