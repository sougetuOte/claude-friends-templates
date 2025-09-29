# Integrated Test Framework

## Overview

This framework provides comprehensive testing support for projects using claude-friends-templates, including:

- End-to-end (E2E) test templates
- Automatic mock generation
- Test scenario management
- CI/CD integration guidelines
- Multi-language support

## Structure

```
test-framework/
├── README.md                # This file
├── templates/              # Test templates by type
│   ├── unit/              # Unit test templates
│   ├── integration/       # Integration test templates
│   ├── e2e/              # End-to-end test templates
│   └── performance/       # Performance test templates
├── mocks/                 # Mock generation utilities
│   ├── generators/        # Mock generators by language
│   └── templates/         # Mock templates
├── scenarios/             # Test scenario definitions
│   ├── common/           # Common test scenarios
│   └── domain/           # Domain-specific scenarios
└── utils/                # Testing utilities
    ├── assertions/       # Custom assertions
    ├── fixtures/         # Test fixtures
    └── helpers/          # Test helpers
```

## Features

### 1. Test Templates

Pre-configured test templates for various testing needs:

- **Unit Tests**: Isolated component testing
- **Integration Tests**: Component interaction testing
- **E2E Tests**: Full workflow testing
- **Performance Tests**: Load and stress testing

### 2. Mock Generation

Automatic mock generation for common patterns:

- API mocks
- Database mocks
- Service mocks
- External dependency mocks

### 3. Test Scenarios

Reusable test scenarios for common use cases:

- Authentication flows
- CRUD operations
- Error handling
- Edge cases

### 4. CI/CD Integration

Ready-to-use configurations for popular CI/CD platforms:

- GitHub Actions
- GitLab CI
- Jenkins
- CircleCI

## Quick Start

### 1. Unit Test Example

```python
# Python example using the framework
from claude_test_framework import TestCase, mock

class UserServiceTest(TestCase):
    def setUp(self):
        self.user_service = UserService()
        self.mock_db = mock.create_database_mock()

    def test_create_user(self):
        # Arrange
        user_data = {"name": "Test User", "email": "test@example.com"}

        # Act
        result = self.user_service.create_user(user_data)

        # Assert
        self.assert_success(result)
        self.assert_user_created(result.user)
```

### 2. E2E Test Example

```javascript
// JavaScript example for E2E testing
const { test, expect } = require('@claude/test-framework');

test.describe('User Registration Flow', () => {
  test('should register new user successfully', async ({ page }) => {
    // Navigate to registration page
    await page.goto('/register');

    // Fill registration form
    await page.fill('[name="username"]', 'testuser');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'SecurePass123!');

    // Submit form
    await page.click('button[type="submit"]');

    // Verify success
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('.welcome-message')).toContainText('Welcome, testuser');
  });
});
```

### 3. Mock Generation Example

```typescript
// TypeScript mock generation
import { generateMock } from '@claude/test-framework/mocks';

interface UserService {
  getUser(id: string): Promise<User>;
  createUser(data: UserData): Promise<User>;
  updateUser(id: string, data: Partial<UserData>): Promise<User>;
}

// Automatically generate mock with sensible defaults
const mockUserService = generateMock<UserService>({
  getUser: { returns: { id: '123', name: 'Test User' } },
  createUser: { validates: ['data.email', 'data.name'] },
  updateUser: { throws: new Error('Not implemented') }
});
```

## Testing Philosophy

### Test-Driven Development (TDD)

Following the Red-Green-Refactor cycle:

1. **Red**: Write failing test first
2. **Green**: Write minimal code to pass
3. **Refactor**: Improve code while keeping tests green

### Test Pyramid

```
       /\
      /  \     E2E Tests (Few)
     /----\
    /      \   Integration Tests (Some)
   /--------\
  /          \ Unit Tests (Many)
 /____________\
```

### Coverage Goals

- **Unit Tests**: 80%+ coverage
- **Integration Tests**: Critical paths covered
- **E2E Tests**: Main user journeys covered

## Best Practices

### 1. Test Naming

Use descriptive names that explain what is being tested:

```javascript
// Good
test('should return error when email is invalid')

// Bad
test('test email validation')
```

### 2. Test Organization

Group related tests logically:

```python
class TestUserAuthentication:
    class TestLogin:
        def test_successful_login_with_valid_credentials(self):
            pass

        def test_failed_login_with_invalid_password(self):
            pass

    class TestLogout:
        def test_successful_logout_clears_session(self):
            pass
```

### 3. Test Data

Use factories and fixtures for consistent test data:

```javascript
const userFactory = {
  create: (overrides = {}) => ({
    id: faker.uuid(),
    name: faker.name(),
    email: faker.email(),
    ...overrides
  })
};

test('user profile update', () => {
  const user = userFactory.create({ name: 'Original Name' });
  // ... test logic
});
```

### 4. Assertions

Use specific assertions for clarity:

```python
# Good - specific assertion
assert user.email == 'test@example.com'
assert response.status_code == 201

# Better - semantic assertions
self.assertEqual(user.email, 'test@example.com')
self.assertCreated(response)
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Test Suite
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Run Unit Tests
        run: |
          npm test:unit

      - name: Run Integration Tests
        run: |
          npm test:integration

      - name: Run E2E Tests
        run: |
          npm test:e2e

      - name: Upload Coverage
        uses: codecov/codecov-action@v1
```

## Language-Specific Guides

- [Python Testing Guide](./guides/python.md)
- [JavaScript/TypeScript Testing Guide](./guides/javascript.md)
- [Java Testing Guide](./guides/java.md)
- [Go Testing Guide](./guides/go.md)

## Troubleshooting

### Common Issues

1. **Flaky Tests**
   - Add proper waits and retries
   - Ensure test isolation
   - Mock external dependencies

2. **Slow Tests**
   - Use test parallelization
   - Optimize database operations
   - Mock heavy operations

3. **False Positives**
   - Verify assertions are specific enough
   - Check for race conditions
   - Ensure proper test cleanup

## Contributing

To add new test patterns or improve the framework:

1. Follow existing patterns
2. Document new features
3. Add examples
4. Test your additions
5. Update relevant guides
