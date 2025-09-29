# テスト構造・組織化ガイド

## テストファイル組織の標準化

### 推奨ディレクトリ構造
```
/src または /lib
  /components
    UserManager.ts
    PaymentProcessor.js
  /services
    AuthService.py
  /utils
    validators.js

/tests
  /unit
    /components
      UserManager.test.ts
      PaymentProcessor.test.js
    /services
      AuthService.test.py
    /utils
      validators.test.js
  /integration
    /api
      auth-api.test.js
      user-api.test.js
  /e2e
    /workflows
      user-signup.test.js
      payment-flow.test.js
  /fixtures
    users.js
    orders.json
  /mocks
    external-apis.js
```

## テスト命名規則

### 基本パターン
```javascript
describe('ComponentName', () => {
  describe('methodName', () => {
    it('should [expected behavior] when [condition]', () => {
      // テストコード
    });
  });
});
```

### 具体的な命名例
```javascript
// ✅ Good - 動作と条件が明確
it('should return user data when valid ID provided')
it('should throw ValidationError when email format is invalid')
it('should calculate total with tax when tax rate is provided')
it('should retry 3 times when network request fails')

// ❌ Bad - 動作が不明確
it('should work')
it('should handle error')
it('should test validation')
```

## テストテンプレート

### 基本テンプレート（JavaScript/TypeScript）
```javascript
describe('UserManager', () => {
  // セットアップ
  beforeEach(() => {
    // テストデータとモックを初期化
    userManager = new UserManager();
    mockDatabase = jest.fn();
  });

  afterEach(() => {
    // クリーンアップ
    jest.clearAllMocks();
  });

  describe('createUser', () => {
    it('should create user with valid data', async () => {
      // Arrange - テストデータの準備
      const userData = {
        name: 'Test User',
        email: 'test@example.com'
      };

      // Act - 機能の実行
      const result = await userManager.createUser(userData);

      // Assert - 結果の検証
      expect(result.id).toBeDefined();
      expect(result.name).toBe('Test User');
      expect(result.email).toBe('test@example.com');
    });

    it('should throw error when email is invalid', async () => {
      // Arrange
      const invalidUserData = {
        name: 'Test User',
        email: 'invalid-email'
      };

      // Act & Assert
      await expect(userManager.createUser(invalidUserData))
        .rejects
        .toThrow('Invalid email format');
    });
  });
});
```

### Python テンプレート
```python
import pytest
from unittest.mock import Mock, patch

class TestUserManager:
    def setup_method(self):
        """各テスト前に実行される"""
        self.user_manager = UserManager()
        self.mock_database = Mock()

    def teardown_method(self):
        """各テスト後に実行される"""
        pass

    def test_create_user_with_valid_data(self):
        # Arrange
        user_data = {
            'name': 'Test User',
            'email': 'test@example.com'
        }

        # Act
        result = self.user_manager.create_user(user_data)

        # Assert
        assert result.id is not None
        assert result.name == 'Test User'
        assert result.email == 'test@example.com'

    def test_create_user_with_invalid_email_raises_error(self):
        # Arrange
        invalid_user_data = {
            'name': 'Test User',
            'email': 'invalid-email'
        }

        # Act & Assert
        with pytest.raises(ValidationError, match='Invalid email format'):
            self.user_manager.create_user(invalid_user_data)
```

## 非同期コードのテストパターン

### JavaScript/TypeScript - async/await
```javascript
describe('AsyncUserService', () => {
  it('should fetch user data asynchronously', async () => {
    // Arrange
    const userId = '123';
    const expectedUser = { id: '123', name: 'John Doe' };
    mockApiCall.mockResolvedValue(expectedUser);

    // Act
    const result = await userService.getUser(userId);

    // Assert
    expect(result).toEqual(expectedUser);
    expect(mockApiCall).toHaveBeenCalledWith('/users/123');
  });

  it('should handle API failure gracefully', async () => {
    // Arrange
    const userId = '123';
    mockApiCall.mockRejectedValue(new Error('Network Error'));

    // Act & Assert
    await expect(userService.getUser(userId))
      .rejects
      .toThrow('Service unavailable');
  });
});
```

### Python - asyncio
```python
import pytest
import asyncio

class TestAsyncUserService:
    @pytest.mark.asyncio
    async def test_fetch_user_data_async(self):
        # Arrange
        user_id = '123'
        expected_user = {'id': '123', 'name': 'John Doe'}

        with patch('user_service.api_call') as mock_api:
            mock_api.return_value = expected_user

            # Act
            result = await user_service.get_user(user_id)

            # Assert
            assert result == expected_user
            mock_api.assert_called_once_with('/users/123')
```

## イベント・コールバックのテストパターン

### JavaScript - Event Testing
```javascript
describe('EventEmitter', () => {
  it('should emit event on state change', () => {
    // Arrange
    const callback = jest.fn();
    const emitter = new StateManager();
    emitter.on('change', callback);

    // Act
    emitter.updateState({ value: 'new' });

    // Assert
    expect(callback).toHaveBeenCalledWith({ value: 'new' });
    expect(callback).toHaveBeenCalledTimes(1);
  });

  it('should remove listener when unsubscribed', () => {
    // Arrange
    const callback = jest.fn();
    const emitter = new StateManager();
    emitter.on('change', callback);

    // Act
    emitter.off('change', callback);
    emitter.updateState({ value: 'new' });

    // Assert
    expect(callback).not.toHaveBeenCalled();
  });
});
```

## テストデータ管理

### Fixtures（固定データ）
```javascript
// fixtures/users.js
export const testUsers = {
  validUser: {
    id: '123',
    name: 'Test User',
    email: 'test@example.com',
    role: 'user'
  },
  adminUser: {
    id: '456',
    name: 'Admin User',
    email: 'admin@example.com',
    role: 'admin'
  },
  invalidUser: {
    id: '',
    name: '',
    email: 'invalid-email'
  }
};
```

### Factories（動的データ生成）
```javascript
// factories/user.factory.js
let userIdCounter = 1;

export function createUser(overrides = {}) {
  return {
    id: `user-${userIdCounter++}`,
    name: `Test User ${userIdCounter}`,
    email: `user${userIdCounter}@example.com`,
    createdAt: new Date(),
    role: 'user',
    ...overrides
  };
}

// 使用例
const user1 = createUser(); // デフォルト値
const admin = createUser({ role: 'admin', name: 'Admin' }); // オーバーライド
```

### Python Fixtures
```python
# conftest.py
import pytest

@pytest.fixture
def valid_user():
    return {
        'id': '123',
        'name': 'Test User',
        'email': 'test@example.com'
    }

@pytest.fixture
def user_factory():
    def _create_user(**overrides):
        defaults = {
            'id': str(uuid.uuid4()),
            'name': 'Test User',
            'email': 'test@example.com',
            'created_at': datetime.now()
        }
        defaults.update(overrides)
        return defaults
    return _create_user

# 使用例
def test_user_creation(valid_user, user_factory):
    # 固定データ使用
    result1 = create_user(valid_user)

    # 動的データ生成
    admin_data = user_factory(role='admin', name='Admin')
    result2 = create_user(admin_data)
```

## CI/CD統合

### Pre-commit Hooks
```bash
#!/bin/sh
# .git/hooks/pre-commit

# 変更されたファイルに対してのみテスト実行
changed_files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|ts|py)$')

if [ -n "$changed_files" ]; then
  echo "Running tests for changed files..."
  npm test -- --findRelatedTests $changed_files

  # テストが失敗した場合はコミットを阻止
  if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
  fi
fi

# カバレッジチェック
npm run test:coverage
if [ $? -ne 0 ]; then
  echo "Coverage threshold not met. Commit aborted."
  exit 1
fi
```

### GitHub Actions例
```yaml
name: Test Suite
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '16'

      - name: Install dependencies
        run: npm install

      - name: Run tests
        run: npm test -- --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v1
        with:
          file: ./coverage/lcov.info
```

## ベストプラクティス まとめ

### Do's ✅
- テストファイル名は実装ファイル名に `.test.` または `.spec.` を追加
- 1つのテストで1つの概念のみをテスト
- Arrange-Act-Assert パターンを使用
- テスト名で期待される動作と条件を明確に
- テスト間の独立性を保つ
- Fixtures と Factories を適切に使い分け

### Don'ts ❌
- 複数の概念を1つのテストに詰め込まない
- テスト間で状態を共有しない
- 実装詳細ではなく動作をテスト
- 外部依存関係をモック化せずにテスト
- テストの保守を怠らない

---
*「良いテスト構造は、良いコード構造の反映である」*
