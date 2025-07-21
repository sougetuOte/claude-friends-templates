/**
 * Basic Playwright E2E Test Template
 * 
 * This template provides a starting point for end-to-end tests using Playwright.
 * Follows TDD principles and includes common testing patterns.
 */

import { test, expect, Page, BrowserContext } from '@playwright/test';
import { TestHelpers } from './helpers';

// Test configuration
test.describe('{Feature} E2E Tests', () => {
  let page: Page;
  let context: BrowserContext;
  let helpers: TestHelpers;
  
  // Test data
  const testData = {
    validUser: {
      username: 'testuser@example.com',
      password: 'SecurePass123!',
    },
    invalidUser: {
      username: 'invalid@example.com',
      password: 'wrongpassword',
    },
  };
  
  // Hooks
  test.beforeAll(async ({ browser }) => {
    // Global setup
    context = await browser.newContext({
      // Context options
      viewport: { width: 1280, height: 720 },
      locale: 'en-US',
    });
  });
  
  test.beforeEach(async () => {
    // Create new page for each test
    page = await context.newPage();
    helpers = new TestHelpers(page);
    
    // Navigate to application
    await page.goto(process.env.BASE_URL || 'http://localhost:3000');
  });
  
  test.afterEach(async () => {
    // Clean up after each test
    await page.close();
  });
  
  test.afterAll(async () => {
    // Global cleanup
    await context.close();
  });
  
  // Test scenarios
  test.describe('Authentication Flow', () => {
    test('should allow valid user to login', async () => {
      // Navigate to login page
      await page.click('text=Login');
      await expect(page).toHaveURL(/.*\/login/);
      
      // Fill login form
      await page.fill('[data-testid="email-input"]', testData.validUser.username);
      await page.fill('[data-testid="password-input"]', testData.validUser.password);
      
      // Submit form
      await page.click('[data-testid="login-button"]');
      
      // Wait for navigation
      await page.waitForURL(/.*\/dashboard/);
      
      // Verify successful login
      await expect(page.locator('[data-testid="user-menu"]')).toBeVisible();
      await expect(page.locator('[data-testid="welcome-message"]')).toContainText('Welcome');
    });
    
    test('should show error for invalid credentials', async () => {
      // Navigate to login
      await page.goto('/login');
      
      // Fill with invalid credentials
      await page.fill('[data-testid="email-input"]', testData.invalidUser.username);
      await page.fill('[data-testid="password-input"]', testData.invalidUser.password);
      
      // Submit
      await page.click('[data-testid="login-button"]');
      
      // Verify error message
      await expect(page.locator('[data-testid="error-message"]')).toBeVisible();
      await expect(page.locator('[data-testid="error-message"]')).toContainText('Invalid credentials');
      
      // Should remain on login page
      await expect(page).toHaveURL(/.*\/login/);
    });
  });
  
  test.describe('User Journey', () => {
    test('should complete full user workflow', async () => {
      // Step 1: Login
      await helpers.login(testData.validUser.username, testData.validUser.password);
      
      // Step 2: Navigate to feature
      await page.click('[data-testid="nav-{feature}"]');
      await expect(page).toHaveURL(/.*\/{feature}/);
      
      // Step 3: Create new item
      await page.click('[data-testid="create-button"]');
      await page.fill('[data-testid="title-input"]', 'Test Item');
      await page.fill('[data-testid="description-input"]', 'Test Description');
      await page.click('[data-testid="save-button"]');
      
      // Step 4: Verify creation
      await expect(page.locator('[data-testid="success-toast"]')).toBeVisible();
      await expect(page.locator('text=Test Item')).toBeVisible();
      
      // Step 5: Edit item
      await page.click('[data-testid="edit-button"]');
      await page.fill('[data-testid="title-input"]', 'Updated Item');
      await page.click('[data-testid="save-button"]');
      
      // Step 6: Verify update
      await expect(page.locator('text=Updated Item')).toBeVisible();
      
      // Step 7: Delete item
      await page.click('[data-testid="delete-button"]');
      await page.click('[data-testid="confirm-delete"]');
      
      // Step 8: Verify deletion
      await expect(page.locator('text=Updated Item')).not.toBeVisible();
    });
  });
  
  test.describe('Responsive Design', () => {
    test('should work on mobile viewport', async () => {
      // Set mobile viewport
      await page.setViewportSize({ width: 375, height: 667 });
      
      // Verify mobile menu
      await expect(page.locator('[data-testid="mobile-menu-button"]')).toBeVisible();
      
      // Open mobile menu
      await page.click('[data-testid="mobile-menu-button"]');
      await expect(page.locator('[data-testid="mobile-menu"]')).toBeVisible();
      
      // Navigate using mobile menu
      await page.click('[data-testid="mobile-nav-{feature}"]');
      await expect(page).toHaveURL(/.*\/{feature}/);
    });
    
    test('should work on tablet viewport', async () => {
      await page.setViewportSize({ width: 768, height: 1024 });
      // Add tablet-specific tests
    });
  });
  
  test.describe('Error Handling', () => {
    test('should handle network errors gracefully', async () => {
      // Simulate network failure
      await page.route('**/api/**', route => route.abort('failed'));
      
      // Attempt action
      await page.click('[data-testid="load-data-button"]');
      
      // Verify error handling
      await expect(page.locator('[data-testid="error-message"]')).toBeVisible();
      await expect(page.locator('[data-testid="retry-button"]')).toBeVisible();
    });
    
    test('should handle 404 pages', async () => {
      // Navigate to non-existent page
      await page.goto('/non-existent-page');
      
      // Verify 404 page
      await expect(page.locator('text=404')).toBeVisible();
      await expect(page.locator('[data-testid="home-link"]')).toBeVisible();
    });
  });
  
  test.describe('Performance', () => {
    test('should load page within acceptable time', async () => {
      const startTime = Date.now();
      
      await page.goto('/');
      await page.waitForLoadState('networkidle');
      
      const loadTime = Date.now() - startTime;
      expect(loadTime).toBeLessThan(3000); // 3 seconds
    });
  });
  
  test.describe('Accessibility', () => {
    test('should be keyboard navigable', async () => {
      // Tab through interactive elements
      await page.keyboard.press('Tab');
      const firstFocused = await page.evaluate(() => document.activeElement?.tagName);
      expect(firstFocused).toBeDefined();
      
      // Continue tabbing and verify focus order
      await page.keyboard.press('Tab');
      await page.keyboard.press('Tab');
      
      // Activate element with Enter
      await page.keyboard.press('Enter');
    });
    
    test('should have proper ARIA labels', async () => {
      const buttons = await page.locator('button').all();
      
      for (const button of buttons) {
        const ariaLabel = await button.getAttribute('aria-label');
        const text = await button.textContent();
        expect(ariaLabel || text).toBeTruthy();
      }
    });
  });
  
  test.describe('Data Persistence', () => {
    test('should persist user preferences', async () => {
      // Set preference
      await page.click('[data-testid="settings-button"]');
      await page.click('[data-testid="dark-mode-toggle"]');
      
      // Reload page
      await page.reload();
      
      // Verify preference persisted
      const isDarkMode = await page.evaluate(() => 
        document.documentElement.classList.contains('dark')
      );
      expect(isDarkMode).toBeTruthy();
    });
  });
});

// Advanced patterns
test.describe('Advanced Patterns', () => {
  test('should handle file uploads', async ({ page }) => {
    await page.goto('/upload');
    
    // Upload file
    const fileInput = await page.locator('input[type="file"]');
    await fileInput.setInputFiles('path/to/test-file.pdf');
    
    // Verify upload
    await expect(page.locator('[data-testid="file-name"]')).toContainText('test-file.pdf');
  });
  
  test('should handle drag and drop', async ({ page }) => {
    await page.goto('/drag-drop');
    
    const source = await page.locator('[data-testid="draggable-item"]');
    const target = await page.locator('[data-testid="drop-zone"]');
    
    await source.dragTo(target);
    
    await expect(target.locator('[data-testid="draggable-item"]')).toBeVisible();
  });
  
  test('should intercept and modify requests', async ({ page }) => {
    // Intercept API calls
    await page.route('**/api/users', route => {
      route.fulfill({
        status: 200,
        body: JSON.stringify([
          { id: 1, name: 'Test User 1' },
          { id: 2, name: 'Test User 2' },
        ]),
      });
    });
    
    await page.goto('/users');
    await expect(page.locator('text=Test User 1')).toBeVisible();
  });
  
  test('should take screenshots for visual regression', async ({ page }) => {
    await page.goto('/');
    
    // Full page screenshot
    await expect(page).toHaveScreenshot('homepage.png', {
      fullPage: true,
      animations: 'disabled',
    });
    
    // Element screenshot
    const header = await page.locator('header');
    await expect(header).toHaveScreenshot('header.png');
  });
});

// Helper class
class TestHelpers {
  constructor(private page: Page) {}
  
  async login(username: string, password: string) {
    await this.page.goto('/login');
    await this.page.fill('[data-testid="email-input"]', username);
    await this.page.fill('[data-testid="password-input"]', password);
    await this.page.click('[data-testid="login-button"]');
    await this.page.waitForURL(/.*\/dashboard/);
  }
  
  async logout() {
    await this.page.click('[data-testid="user-menu"]');
    await this.page.click('[data-testid="logout-button"]');
    await this.page.waitForURL(/.*\/login/);
  }
  
  async waitForApiResponse(endpoint: string) {
    return this.page.waitForResponse(response => 
      response.url().includes(endpoint) && response.status() === 200
    );
  }
}