# Testing WooCommerce with WP Testing Framework

This guide shows how to use the framework to test WooCommerce.

## Installation

```bash
bash install-wp-testing-framework.sh --plugin woocommerce --name "WooCommerce Tests"
```

## What Gets Tested

The framework automatically detects and creates tests for:

- Product management
- Cart functionality
- Checkout process
- Payment gateways
- Order management
- Customer accounts
- REST API endpoints
- Gutenberg blocks
- Admin pages
- Email notifications

## Generated Test Examples

### PHPUnit Integration Test

```php
class WooCommerceIntegrationTest extends WP_UnitTestCase {
    
    public function test_create_simple_product() {
        $product = new WC_Product_Simple();
        $product->set_name('Test Product');
        $product->set_price(19.99);
        $product->save();
        
        $this->assertGreaterThan(0, $product->get_id());
        $this->assertEquals('Test Product', $product->get_name());
    }
    
    public function test_add_to_cart() {
        $product = WC_Helper_Product::create_simple_product();
        WC()->cart->add_to_cart($product->get_id(), 1);
        
        $this->assertEquals(1, WC()->cart->get_cart_contents_count());
    }
}
```

### Playwright E2E Test

```typescript
test('complete purchase flow', async ({ page }) => {
    // Add product to cart
    await page.goto('/shop');
    await page.click('.products .product:first-child .add_to_cart_button');
    
    // Go to cart
    await page.goto('/cart');
    await expect(page.locator('.cart_item')).toBeVisible();
    
    // Proceed to checkout
    await page.click('.checkout-button');
    
    // Fill billing details
    await page.fill('#billing_first_name', 'John');
    await page.fill('#billing_last_name', 'Doe');
    await page.fill('#billing_email', 'john@example.com');
    // ... more fields
    
    // Place order
    await page.click('#place_order');
    
    // Verify order received
    await expect(page.locator('.woocommerce-thankyou-order-received')).toBeVisible();
});
```

## Running Tests

```bash
# Run all tests
npm test

# Run specific test suites
npm run test:unit        # Unit tests only
npm run test:integration # Integration tests
npm run test:e2e        # E2E tests
```

## Custom Test Scenarios

You can extend the generated tests for specific WooCommerce features:

- Subscription products
- Variable products
- Coupons and discounts
- Tax calculations
- Shipping methods
- Payment gateway integrations
- Multi-currency support
- Inventory management