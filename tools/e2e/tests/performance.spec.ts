import { test, expect } from '@playwright/test';

test.describe('BuddyPress Performance Tests', () => {
  const baseUrl = process.env.E2E_BASE_URL || 'http://buddynext.local';
  const username = process.env.E2E_USER || 'admin';
  const password = process.env.E2E_PASS || 'password';

  // Performance thresholds (in milliseconds)
  const PERFORMANCE_THRESHOLDS = {
    pageLoad: 3000,        // 3 seconds max for page load
    firstContentfulPaint: 1500, // 1.5 seconds max for FCP
    largestContentfulPaint: 2500, // 2.5 seconds max for LCP
    timeToInteractive: 3500,     // 3.5 seconds max for TTI
    cumulativeLayoutShift: 0.1,  // Max CLS score
  };

  test.beforeEach(async ({ page }) => {
    // Login as admin for authenticated tests
    await page.goto(`${baseUrl}/wp-login.php`);
    await page.fill('#user_login', username);
    await page.fill('#user_pass', password);
    await page.click('#wp-submit');
    await page.waitForLoadState('networkidle');
  });

  test('homepage should load within performance budget', async ({ page }) => {
    const startTime = Date.now();
    
    await page.goto(`${baseUrl}/`);
    await page.waitForLoadState('networkidle');
    
    const loadTime = Date.now() - startTime;
    console.log(`Homepage load time: ${loadTime}ms`);
    
    expect(loadTime).toBeLessThan(PERFORMANCE_THRESHOLDS.pageLoad);
  });

  test('activity page should meet performance criteria', async ({ page }) => {
    const startTime = Date.now();
    
    await page.goto(`${baseUrl}/activity`);
    await page.waitForLoadState('networkidle');
    
    const loadTime = Date.now() - startTime;
    console.log(`Activity page load time: ${loadTime}ms`);
    
    expect(loadTime).toBeLessThan(PERFORMANCE_THRESHOLDS.pageLoad);
    
    // Check for performance markers
    const performanceTiming = await page.evaluate(() => {
      return JSON.stringify(window.performance.timing);
    });
    
    const timing = JSON.parse(performanceTiming);
    const domContentLoaded = timing.domContentLoadedEventEnd - timing.navigationStart;
    
    console.log(`DOM content loaded: ${domContentLoaded}ms`);
    expect(domContentLoaded).toBeLessThan(PERFORMANCE_THRESHOLDS.firstContentfulPaint);
  });

  test('members directory should load efficiently', async ({ page }) => {
    const startTime = Date.now();
    
    await page.goto(`${baseUrl}/members`);
    await page.waitForLoadState('networkidle');
    
    const loadTime = Date.now() - startTime;
    console.log(`Members directory load time: ${loadTime}ms`);
    
    expect(loadTime).toBeLessThan(PERFORMANCE_THRESHOLDS.pageLoad);
    
    // Check that member avatars are optimized (lazy loaded)
    const images = page.locator('img');
    const imageCount = await images.count();
    
    if (imageCount > 0) {
      // Check for lazy loading attributes
      const firstImage = images.first();
      const loading = await firstImage.getAttribute('loading');
      console.log(`Image loading strategy: ${loading || 'immediate'}`);
    }
  });

  test('groups directory should handle large datasets', async ({ page }) => {
    const startTime = Date.now();
    
    await page.goto(`${baseUrl}/groups`);
    await page.waitForLoadState('networkidle');
    
    const loadTime = Date.now() - startTime;
    console.log(`Groups directory load time: ${loadTime}ms`);
    
    expect(loadTime).toBeLessThan(PERFORMANCE_THRESHOLDS.pageLoad);
    
    // Check pagination is implemented for large datasets
    const paginationExists = await page.locator('.pagination, .pag-count').count() > 0;
    if (paginationExists) {
      console.log('✅ Pagination implemented for groups directory');
    }
  });

  test('user profile should load quickly', async ({ page }) => {
    const startTime = Date.now();
    
    await page.goto(`${baseUrl}/members/${username}`);
    await page.waitForLoadState('networkidle');
    
    const loadTime = Date.now() - startTime;
    console.log(`User profile load time: ${loadTime}ms`);
    
    expect(loadTime).toBeLessThan(PERFORMANCE_THRESHOLDS.pageLoad);
  });

  test('should measure Core Web Vitals', async ({ page }) => {
    await page.goto(`${baseUrl}/`);
    
    // Measure Core Web Vitals using Performance Observer API
    const webVitals = await page.evaluate(() => {
      return new Promise((resolve) => {
        const vitals = {};
        
        // Largest Contentful Paint
        new PerformanceObserver((entryList) => {
          const entries = entryList.getEntries();
          const lastEntry = entries[entries.length - 1];
          vitals.LCP = lastEntry.startTime;
        }).observe({ entryTypes: ['largest-contentful-paint'] });
        
        // First Input Delay (if available)
        new PerformanceObserver((entryList) => {
          const entries = entryList.getEntries();
          vitals.FID = entries[0].processingStart - entries[0].startTime;
        }).observe({ entryTypes: ['first-input'] });
        
        // Cumulative Layout Shift
        new PerformanceObserver((entryList) => {
          let clsValue = 0;
          for (const entry of entryList.getEntries()) {
            if (!entry.hadRecentInput) {
              clsValue += entry.value;
            }
          }
          vitals.CLS = clsValue;
        }).observe({ entryTypes: ['layout-shift'] });
        
        // Return measurements after a delay
        setTimeout(() => resolve(vitals), 3000);
      });
    });
    
    console.log('Core Web Vitals:', webVitals);
    
    // Test LCP (should be under 2.5 seconds)
    if (webVitals.LCP) {
      expect(webVitals.LCP).toBeLessThan(PERFORMANCE_THRESHOLDS.largestContentfulPaint);
    }
    
    // Test CLS (should be under 0.1)
    if (webVitals.CLS !== undefined) {
      expect(webVitals.CLS).toBeLessThan(PERFORMANCE_THRESHOLDS.cumulativeLayoutShift);
    }
  });

  test('should have optimized resource loading', async ({ page }) => {
    await page.goto(`${baseUrl}/`);
    
    // Check for resource optimization
    const resourceTiming = await page.evaluate(() => {
      const resources = performance.getEntriesByType('resource');
      return {
        totalResources: resources.length,
        cssFiles: resources.filter(r => r.name.includes('.css')).length,
        jsFiles: resources.filter(r => r.name.includes('.js')).length,
        images: resources.filter(r => r.initiatorType === 'img').length,
        largeResources: resources.filter(r => r.transferSize > 1024 * 1024).length, // > 1MB
      };
    });
    
    console.log('Resource loading stats:', resourceTiming);
    
    // Should not have too many resources
    expect(resourceTiming.totalResources).toBeLessThan(100);
    
    // Should not have resources larger than 1MB
    expect(resourceTiming.largeResources).toBe(0);
  });

  test('database queries should be optimized', async ({ page }) => {
    // This test would require WordPress Query Debug plugin or similar
    // For now, we'll test page load times as a proxy for query optimization
    
    const pages = [
      '/',
      '/activity',
      '/members',
      '/groups',
    ];
    
    for (const pagePath of pages) {
      const startTime = Date.now();
      
      await page.goto(`${baseUrl}${pagePath}`);
      await page.waitForLoadState('networkidle');
      
      const loadTime = Date.now() - startTime;
      console.log(`${pagePath} load time: ${loadTime}ms`);
      
      // Each page should load within reasonable time
      expect(loadTime).toBeLessThan(PERFORMANCE_THRESHOLDS.pageLoad);
    }
  });

  test('AJAX requests should be performant', async ({ page }) => {
    await page.goto(`${baseUrl}/activity`);
    
    // Monitor network requests
    const ajaxRequests = [];
    
    page.on('response', response => {
      const url = response.url();
      if (url.includes('admin-ajax.php') || url.includes('/wp-json/')) {
        ajaxRequests.push({
          url,
          status: response.status(),
          timing: response.timing(),
        });
      }
    });
    
    // Trigger AJAX activity (like loading more activities)
    const loadMoreButton = page.locator('.load-more, #load-more');
    if (await loadMoreButton.count() > 0) {
      await loadMoreButton.click();
      await page.waitForLoadState('networkidle');
    }
    
    // Check AJAX performance
    for (const request of ajaxRequests) {
      console.log(`AJAX request: ${request.url} - ${request.status}`);
      expect(request.status).toBe(200);
      
      if (request.timing) {
        const responseTime = request.timing.responseEnd - request.timing.requestStart;
        expect(responseTime).toBeLessThan(2000); // AJAX should respond within 2 seconds
      }
    }
  });

  test('memory usage should be reasonable', async ({ page }) => {
    await page.goto(`${baseUrl}/`);
    
    // Measure memory usage using Performance API
    const memoryInfo = await page.evaluate(() => {
      // @ts-ignore - performance.memory is Chrome-specific
      const memory = performance.memory;
      if (memory) {
        return {
          usedJSHeapSize: memory.usedJSHeapSize,
          totalJSHeapSize: memory.totalJSHeapSize,
          jsHeapSizeLimit: memory.jsHeapSizeLimit,
        };
      }
      return null;
    });
    
    if (memoryInfo) {
      console.log('Memory usage:', memoryInfo);
      
      // Memory usage should be reasonable (less than 50MB for JS heap)
      expect(memoryInfo.usedJSHeapSize).toBeLessThan(50 * 1024 * 1024);
    }
  });

  test('should handle concurrent user simulation', async ({ page, browser }) => {
    // Simulate multiple users accessing the site
    const contexts = await Promise.all([
      browser.newContext(),
      browser.newContext(),
      browser.newContext(),
    ]);
    
    const pages = await Promise.all(contexts.map(ctx => ctx.newPage()));
    
    // Have all pages load different sections simultaneously
    const startTime = Date.now();
    
    await Promise.all([
      pages[0].goto(`${baseUrl}/`),
      pages[1].goto(`${baseUrl}/activity`),
      pages[2].goto(`${baseUrl}/members`),
    ]);
    
    await Promise.all(pages.map(p => p.waitForLoadState('networkidle')));
    
    const totalTime = Date.now() - startTime;
    console.log(`Concurrent load time: ${totalTime}ms`);
    
    // Should handle concurrent loads reasonably well
    expect(totalTime).toBeLessThan(PERFORMANCE_THRESHOLDS.pageLoad * 2);
    
    // Cleanup
    await Promise.all(contexts.map(ctx => ctx.close()));
  });
});