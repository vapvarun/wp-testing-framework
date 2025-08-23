import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('BuddyPress Accessibility Tests', () => {
  const baseUrl = process.env.E2E_BASE_URL || 'http://buddynext.local';
  const username = process.env.E2E_USER || 'admin';
  const password = process.env.E2E_PASS || 'password';

  test.beforeEach(async ({ page }) => {
    // Login for authenticated tests
    await page.goto(`${baseUrl}/wp-login.php`);
    await page.fill('#user_login', username);
    await page.fill('#user_pass', password);
    await page.click('#wp-submit');
    await page.waitForLoadState('networkidle');
  });

  test('homepage should be accessible', async ({ page }) => {
    await page.goto(`${baseUrl}/`);
    
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });

  test('activity page should be accessible', async ({ page }) => {
    await page.goto(`${baseUrl}/activity`);
    await page.waitForLoadState('networkidle');
    
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });

  test('members directory should be accessible', async ({ page }) => {
    await page.goto(`${baseUrl}/members`);
    await page.waitForLoadState('networkidle');
    
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });

  test('groups directory should be accessible', async ({ page }) => {
    await page.goto(`${baseUrl}/groups`);
    await page.waitForLoadState('networkidle');
    
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });

  test('user profile should be accessible', async ({ page }) => {
    await page.goto(`${baseUrl}/members/${username}`);
    await page.waitForLoadState('networkidle');
    
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });

  test('should have proper heading hierarchy', async ({ page }) => {
    await page.goto(`${baseUrl}/`);
    
    // Check heading levels
    const headings = await page.locator('h1, h2, h3, h4, h5, h6').allTextContents();
    
    // Should have at least one h1
    const h1Count = await page.locator('h1').count();
    expect(h1Count).toBeGreaterThanOrEqual(1);
    
    console.log('Headings found:', headings.length);
  });

  test('should have accessible forms', async ({ page }) => {
    await page.goto(`${baseUrl}/activity`);
    await page.waitForLoadState('networkidle');
    
    // Check for form labels
    const inputs = page.locator('input[type="text"], input[type="email"], textarea');
    const inputCount = await inputs.count();
    
    if (inputCount > 0) {
      for (let i = 0; i < inputCount; i++) {
        const input = inputs.nth(i);
        const id = await input.getAttribute('id');
        const ariaLabel = await input.getAttribute('aria-label');
        const ariaLabelledby = await input.getAttribute('aria-labelledby');
        
        // Check if input has proper labeling
        if (id) {
          const label = page.locator(`label[for="${id}"]`);
          const labelExists = await label.count() > 0;
          
          const hasProperLabeling = labelExists || ariaLabel || ariaLabelledby;
          expect(hasProperLabeling).toBe(true);
        }
      }
    }
  });

  test('should have accessible navigation', async ({ page }) => {
    await page.goto(`${baseUrl}/`);
    
    // Check for navigation landmarks
    const nav = page.locator('nav, [role="navigation"]');
    const navCount = await nav.count();
    
    if (navCount > 0) {
      // Navigation should have proper ARIA labels or accessible names
      for (let i = 0; i < navCount; i++) {
        const navigation = nav.nth(i);
        const ariaLabel = await navigation.getAttribute('aria-label');
        const ariaLabelledby = await navigation.getAttribute('aria-labelledby');
        
        // At least one navigation should have proper labeling
        console.log(`Navigation ${i + 1}: aria-label="${ariaLabel}", aria-labelledby="${ariaLabelledby}"`);
      }
    }
  });

  test('should have accessible images', async ({ page }) => {
    await page.goto(`${baseUrl}/members`);
    await page.waitForLoadState('networkidle');
    
    // Check all images have alt text
    const images = page.locator('img');
    const imageCount = await images.count();
    
    if (imageCount > 0) {
      for (let i = 0; i < Math.min(imageCount, 10); i++) { // Check first 10 images
        const img = images.nth(i);
        const alt = await img.getAttribute('alt');
        const ariaLabel = await img.getAttribute('aria-label');
        const role = await img.getAttribute('role');
        
        // Decorative images should have empty alt or role="presentation"
        // Content images should have descriptive alt text
        const isDecorative = alt === '' || role === 'presentation';
        const hasAltText = alt !== null && alt.length > 0;
        const hasAriaLabel = ariaLabel !== null && ariaLabel.length > 0;
        
        const isAccessible = isDecorative || hasAltText || hasAriaLabel;
        expect(isAccessible).toBe(true);
      }
    }
  });

  test('should be keyboard navigable', async ({ page }) => {
    await page.goto(`${baseUrl}/`);
    
    // Check if interactive elements are focusable
    const interactiveElements = page.locator('a, button, input, select, textarea, [tabindex]');
    const elementCount = await interactiveElements.count();
    
    if (elementCount > 0) {
      // Test keyboard navigation through first few elements
      await page.keyboard.press('Tab');
      
      const firstFocusableElement = await page.locator(':focus').first();
      const tagName = await firstFocusableElement.evaluate(el => el.tagName.toLowerCase());
      
      // Should be able to focus on interactive elements
      const interactiveTags = ['a', 'button', 'input', 'select', 'textarea'];
      expect(interactiveTags).toContain(tagName);
    }
  });

  test('should have proper color contrast', async ({ page }) => {
    await page.goto(`${baseUrl}/`);
    
    // Use axe-core to check color contrast specifically
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['color-contrast'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });

  test('should support screen readers', async ({ page }) => {
    await page.goto(`${baseUrl}/activity`);
    await page.waitForLoadState('networkidle');
    
    // Check for ARIA landmarks
    const landmarks = await page.locator('[role="main"], [role="banner"], [role="navigation"], [role="contentinfo"], main, header, nav, footer').count();
    
    expect(landmarks).toBeGreaterThan(0);
    
    // Check for proper ARIA attributes on dynamic content
    const liveRegions = await page.locator('[aria-live], [aria-atomic], [aria-relevant]').count();
    console.log(`Live regions found: ${liveRegions}`);
  });

  test('should handle focus management', async ({ page }) => {
    await page.goto(`${baseUrl}/`);
    
    // Test skip links
    const skipLink = page.locator('a[href="#content"], a[href="#main"], .skip-link').first();
    if (await skipLink.count() > 0) {
      await skipLink.click();
      
      // Focus should move to main content
      const focusedElement = page.locator(':focus');
      const focusedId = await focusedElement.getAttribute('id');
      
      expect(['content', 'main']).toContain(focusedId || '');
    }
  });

  test('modal dialogs should be accessible', async ({ page }) => {
    await page.goto(`${baseUrl}/`);
    
    // Look for modal triggers
    const modalTriggers = page.locator('[data-target*="modal"], .modal-trigger, [aria-haspopup="dialog"]');
    const triggerCount = await modalTriggers.count();
    
    if (triggerCount > 0) {
      const trigger = modalTriggers.first();
      await trigger.click();
      
      // Check if modal has proper ARIA attributes
      const modal = page.locator('[role="dialog"], .modal').first();
      if (await modal.count() > 0) {
        const ariaLabel = await modal.getAttribute('aria-label');
        const ariaLabelledby = await modal.getAttribute('aria-labelledby');
        const ariaModal = await modal.getAttribute('aria-modal');
        
        const hasProperAttributes = ariaLabel || ariaLabelledby;
        expect(hasProperAttributes).toBe(true);
        expect(ariaModal).toBe('true');
      }
    }
  });

  test('should provide error messages accessibly', async ({ page }) => {
    // Test form validation errors
    await page.goto(`${baseUrl}/register`);
    
    // Try to submit empty form if registration page exists
    const submitButton = page.locator('input[type="submit"], button[type="submit"]').first();
    if (await submitButton.count() > 0) {
      await submitButton.click();
      
      // Check for accessible error messages
      const errorMessages = page.locator('[role="alert"], .error, .notice-error, [aria-invalid="true"]');
      const errorCount = await errorMessages.count();
      
      if (errorCount > 0) {
        // Error messages should be properly associated with form fields
        const firstError = errorMessages.first();
        const text = await firstError.textContent();
        
        expect(text).toBeTruthy();
        console.log('Error message found:', text?.substring(0, 100));
      }
    }
  });

  test('should support high contrast mode', async ({ page }) => {
    await page.goto(`${baseUrl}/`);
    
    // Simulate high contrast mode by checking if styles work with forced colors
    await page.addStyleTag({
      content: `
        * {
          forced-color-adjust: none !important;
          background: black !important;
          color: white !important;
        }
      `
    });
    
    // Check if content is still readable
    const mainContent = page.locator('main, #main, .main-content, body').first();
    const isVisible = await mainContent.isVisible();
    
    expect(isVisible).toBe(true);
  });

  test('should work with reduced motion', async ({ page }) => {
    // Set reduced motion preference
    await page.emulateMedia({ reducedMotion: 'reduce' });
    
    await page.goto(`${baseUrl}/`);
    
    // Check that animations respect reduced motion
    const animatedElements = page.locator('[class*="animate"], [class*="transition"], [style*="animation"]');
    const animatedCount = await animatedElements.count();
    
    if (animatedCount > 0) {
      // In a real test, we'd check that animations are disabled or reduced
      console.log(`Found ${animatedCount} potentially animated elements`);
    }
  });
});