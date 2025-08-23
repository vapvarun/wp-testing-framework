# Contributing to WordPress Universal Testing Framework

First off, thank you for considering contributing to this project! 🎉

## Code of Conduct

This project adheres to the WordPress Community Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, please include:

- A clear and descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- WordPress version, PHP version, and plugin/theme being tested
- Any error messages or screenshots

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- A clear and descriptive title
- A detailed description of the proposed enhancement
- Use cases and examples
- Why this enhancement would be useful

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code, add tests
3. Ensure the test suite passes
4. Make sure your code follows WordPress Coding Standards
5. Issue that pull request!

## Development Setup

```bash
# Clone your fork
git clone https://github.com/your-username/wp-testing-framework.git

# Install dependencies
npm install
composer install

# Run tests
npm test
```

## Coding Standards

- Follow [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/)
- Use meaningful variable and function names
- Comment your code where necessary
- Write tests for new features

## Testing

- Write PHPUnit tests for PHP code
- Write Playwright/Cypress tests for UI features
- Ensure all tests pass before submitting PR

## Documentation

- Update README.md if needed
- Add JSDoc comments for JavaScript functions
- Add PHPDoc comments for PHP functions
- Update CHANGELOG.md for notable changes

## Questions?

Feel free to open an issue with your question or reach out via GitHub Discussions.

Thank you! ❤️