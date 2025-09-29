# Test Framework Quick Start Guide

## Getting Started in 5 Minutes

### 1. Choose Your Test Type

```bash
# Unit Test
cp .claude/shared/test-framework/templates/unit/[language]/basic_test_template.[ext] tests/unit/

# Integration Test
cp .claude/shared/test-framework/templates/integration/basic_integration_template.[ext] tests/integration/

# E2E Test
cp .claude/shared/test-framework/templates/e2e/[tool]/basic_e2e_template.[ext] tests/e2e/
```

### 2. Generate Mock Data

```python
# Quick mock generation
from claude_test_framework.mocks import generate_from_schema

# Define your data schema
user_schema = {
    "id": {"type": "uuid"},
    "email": {"type": "email"},
    "name": {"type": "string", "length": 20},
    "active": {"type": "boolean"}
}

# Generate mock data
mock_user = generate_from_schema(user_schema)
mock_users = generate_from_schema(user_schema, count=10)
```

### 3. Write Your First Test

#### JavaScript/TypeScript Example

```javascript
// tests/unit/user-service.test.js
const { UserService } = require('../src/services/user-service');

describe('UserService', () => {
  let userService;

  beforeEach(() => {
    userService = new UserService();
  });

  test('should create user successfully', async () => {
    // Arrange
    const userData = {
      email: 'test@example.com',
      name: 'Test User'
    };

    // Act
    const user = await userService.createUser(userData);

    // Assert
    expect(user).toHaveProperty('id');
    expect(user.email).toBe(userData.email);
    expect(user.name).toBe(userData.name);
  });
});
```

#### Python Example

```python
# tests/unit/test_user_service.py
import unittest
from src.services.user_service import UserService

class TestUserService(unittest.TestCase):
    def setUp(self):
        self.user_service = UserService()

    def test_create_user_success(self):
        # Arrange
        user_data = {
            'email': 'test@example.com',
            'name': 'Test User'
        }

        # Act
        user = self.user_service.create_user(user_data)

        # Assert
        self.assertIsNotNone(user['id'])
        self.assertEqual(user['email'], user_data['email'])
        self.assertEqual(user['name'], user_data['name'])
```

### 4. Run Tests

```bash
# JavaScript/TypeScript
npm test                  # Run all tests
npm run test:unit        # Run unit tests only
npm run test:watch       # Run tests in watch mode

# Python
python -m pytest         # Run all tests
pytest tests/unit/       # Run unit tests only
pytest -v               # Verbose output
pytest --cov=src        # With coverage
```

### 5. Set Up CI/CD

```yaml
# .github/workflows/test.yml (minimal example)
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm test
```

## Common Patterns

### Testing Async Code

```javascript
// Async/Await
test('async operation', async () => {
  const result = await asyncFunction();
  expect(result).toBe('expected');
});

// Promises
test('promise operation', () => {
  return promiseFunction().then(result => {
    expect(result).toBe('expected');
  });
});
```

### Testing with Mocks

```javascript
// Jest mocking
jest.mock('../src/services/email-service');

test('sends email on user creation', async () => {
  const { EmailService } = require('../src/services/email-service');
  EmailService.send = jest.fn().mockResolvedValue(true);

  await userService.createUser(userData);

  expect(EmailService.send).toHaveBeenCalledWith(
    expect.objectContaining({
      to: userData.email,
      subject: 'Welcome!'
    })
  );
});
```

### Testing API Endpoints

```javascript
// Using supertest
const request = require('supertest');
const app = require('../src/app');

test('GET /api/users', async () => {
  const response = await request(app)
    .get('/api/users')
    .expect('Content-Type', /json/)
    .expect(200);

  expect(response.body).toHaveProperty('users');
  expect(Array.isArray(response.body.users)).toBe(true);
});
```

## TDD Workflow

### 1. Red Phase - Write Failing Test

```javascript
test('calculates discount correctly', () => {
  const price = 100;
  const discountPercent = 20;

  const discounted = calculateDiscount(price, discountPercent);

  expect(discounted).toBe(80); // This will fail initially
});
```

### 2. Green Phase - Make Test Pass

```javascript
function calculateDiscount(price, discountPercent) {
  return price - (price * discountPercent / 100);
}
```

### 3. Refactor Phase - Improve Code

```javascript
function calculateDiscount(price, discountPercent) {
  if (price < 0 || discountPercent < 0 || discountPercent > 100) {
    throw new Error('Invalid input');
  }

  const discountAmount = price * (discountPercent / 100);
  return Number((price - discountAmount).toFixed(2));
}
```

## Quick Commands Reference

```bash
# Generate mock data
python .claude/shared/test-framework/mocks/mock-generator.py

# Search error patterns
python .claude/shared/error-patterns/search-patterns.py "TypeError"

# Run specific test file
npm test -- user-service.test.js
pytest tests/unit/test_user_service.py

# Run tests with coverage
npm test -- --coverage
pytest --cov=src --cov-report=html

# Run tests in watch mode
npm test -- --watch
pytest-watch

# Run E2E tests
npm run test:e2e
playwright test

# Debug tests
npm test -- --inspect-brk
pytest --pdb
```

## Tips for Success

1. **Start Simple**: Begin with unit tests for pure functions
2. **Use Templates**: Copy and modify provided templates
3. **Mock External Dependencies**: Keep tests isolated and fast
4. **Write Descriptive Test Names**: Test names should explain what and why
5. **Follow AAA Pattern**: Arrange, Act, Assert
6. **One Assertion Per Test**: Keep tests focused
7. **Run Tests Frequently**: Use watch mode during development
8. **Keep Tests Fast**: Mock heavy operations
9. **Test Edge Cases**: Don't just test the happy path
10. **Maintain Tests**: Update tests when requirements change

## Next Steps

- Explore [test scenarios](./scenarios/common/) for common patterns
- Read the [CI/CD integration guide](./ci-cd-integration.md)
- Check [error patterns](../error-patterns/) when tests fail
- Review framework [best practices](./README.md#best-practices)
