# Test Directory Structure

## Organization

```
tests/
├── framework/           # Universal framework tests
│   ├── unit/           # Unit tests for framework
│   ├── integration/    # Integration tests
│   └── bootstrap*.php  # Test bootstrap files
├── e2e/                # End-to-end tests
│   ├── specs/          # E2E test specifications
│   └── fixtures/       # Test data
├── functionality/      # Functionality tests
└── templates/          # Test generation templates

plugins/{plugin}/tests/ # Plugin-specific tests
├── unit/              # Plugin unit tests
├── integration/       # Plugin integration tests
├── security/          # Security tests
└── performance/       # Performance tests
```

## Where Tests Should Go

### Framework Tests
- Location: `/tests/framework/`
- Purpose: Test the testing framework itself
- Example: Testing scanners, generators, utilities

### Plugin Tests
- Location: `/plugins/{plugin}/tests/`
- Purpose: Plugin-specific test cases
- Example: BuddyPress component tests

### E2E Tests
- Location: `/tests/e2e/`
- Purpose: Browser-based user journey tests
- Example: Complete user registration flow

## Running Tests

```bash
# Framework tests
./vendor/bin/phpunit tests/framework/

# Plugin tests (e.g., BuddyPress)
./vendor/bin/phpunit plugins/buddypress/tests/

# E2E tests
npx playwright test tests/e2e/

# All tests
npm run test:all
```

## Test Types

1. **Unit Tests** - Test individual functions/methods
2. **Integration Tests** - Test component interactions
3. **E2E Tests** - Test complete user workflows
4. **Security Tests** - Test for vulnerabilities
5. **Performance Tests** - Test speed and resource usage
6. **UX Tests** - Test accessibility and responsiveness

## Best Practices

1. Keep framework tests separate from plugin tests
2. Use consistent naming: `*Test.php` for test files
3. Group related tests in subdirectories
4. Include fixtures/data in test directories
5. Document complex test scenarios