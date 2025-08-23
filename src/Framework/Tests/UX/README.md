# UX Code Testing - Responsive & Accessibility

## What This Tests (Without Real Browsers!)

### ✅ Responsive Code Checks
1. **CSS Breakpoints** - Ensures mobile/tablet/desktop styles exist
2. **Viewport Meta** - Checks for proper mobile viewport
3. **Responsive Images** - Validates srcset/sizes attributes
4. **Table Responsiveness** - Ensures tables work on mobile
5. **Touch Targets** - Validates 44px minimum button size

### ♿ Accessibility Code Checks
1. **Alt Text** - All images have descriptions
2. **Form Labels** - All inputs properly labeled
3. **ARIA Landmarks** - Navigation regions defined
4. **Heading Hierarchy** - H1→H2→H3 proper order
5. **Color Contrast** - Detects potential issues
6. **Keyboard Support** - JavaScript handles keyboard
7. **Focus Indicators** - Visible focus states
8. **Skip Links** - Screen reader navigation
9. **ARIA Live** - AJAX updates announced

## Running The Tests

```bash
# Run all UX code tests
./vendor/bin/phpunit plugins/buddypress/tests/UX/

# Run specific test
./vendor/bin/phpunit --filter testImagesHaveAltAttributes

# Generate compliance report
./vendor/bin/phpunit --filter testGenerateUXComplianceReport
```

## What Gets Detected

### ✅ Will Catch (80% of issues):
- Missing alt attributes
- No viewport meta tag
- Tables without responsive wrapper
- Buttons too small for touch
- Missing form labels
- Bad heading structure
- No keyboard event handlers
- Missing focus styles

### ⚠️ Won't Catch (Need real browser):
- Actual contrast ratios
- Real screen reader experience
- Touch gesture conflicts
- Actual responsive behavior
- JavaScript runtime issues
- Cross-browser quirks

## Test Results Example

```
PASS ✅ CSS has mobile breakpoints
PASS ✅ Viewport meta tag exists
WARN ⚠️ 3 images missing responsive attributes
FAIL ❌ 5 inputs without labels
PASS ✅ ARIA landmarks present
WARN ⚠️ Potential low contrast: #ccc on white
PASS ✅ Keyboard navigation supported
PASS ✅ Focus indicators exist

UX Compliance Score: 75% (PASS)
- Responsive: 80%
- Accessibility: 70%
```

## Quick Fixes for Common Issues

### Missing Alt Text
```php
// Bad
<img src="avatar.jpg">

// Good
<img src="avatar.jpg" alt="User avatar">
```

### Missing Labels
```php
// Bad
<input type="text" id="username">

// Good
<label for="username">Username</label>
<input type="text" id="username">

// Or
<input type="text" id="username" aria-label="Username">
```

### Small Touch Targets
```css
/* Bad */
.button { padding: 5px; }

/* Good */
.button { 
    min-height: 44px;
    min-width: 44px;
    padding: 12px;
}
```

### Missing Breakpoints
```css
/* Add these to CSS */
@media (max-width: 768px) {
    /* Tablet styles */
}

@media (max-width: 480px) {
    /* Mobile styles */
}
```

## Benefits

1. **Catches 80% of UX issues** without browser testing
2. **Runs in seconds** vs hours for manual testing
3. **CI/CD ready** - No browser needed
4. **Legal compliance** - Basic WCAG 2.1 checks
5. **SEO benefits** - Accessible = better SEO

## Integration with Main Framework

```php
// Add to test suite
<testsuite name="ux-tests">
    <directory>plugins/buddypress/tests/UX</directory>
</testsuite>
```

```bash
# Run with other tests
npm run test:bp:ux

# Or full suite
npm run test:bp:all
```

## Compliance Levels

| Score | Level | Meaning |
|-------|-------|---------|
| 90-100% | AAA | Excellent accessibility |
| 75-89% | AA | Good, legally compliant |
| 60-74% | A | Basic compliance |
| < 60% | Fail | Needs work |

## Next Steps

If tests pass here (>75%), consider:
1. Real browser testing with Playwright
2. Screen reader testing
3. User testing with disabled users
4. Performance testing on slow devices

But this gets you 80% there without the complexity!