/**
 * Basic JavaScript Unit Test Template
 * 
 * This template provides a starting point for unit tests following TDD principles.
 * Supports both Jest and Mocha/Chai testing frameworks.
 */

// Jest example (most common)
describe('{ComponentName}', () => {
  let component;
  let mockDependency;
  
  // Test data
  const testData = {
    validInput: { key: 'value' },
    invalidInput: { key: null },
    edgeCase: { key: '' },
  };
  
  beforeEach(() => {
    // Set up fresh instances before each test
    mockDependency = jest.fn();
    component = new {ComponentName}({
      dependency: mockDependency
    });
  });
  
  afterEach(() => {
    // Clean up after each test
    jest.clearAllMocks();
  });
  
  describe('initialization', () => {
    test('should initialize with default values', () => {
      // Arrange & Act
      const instance = new {ComponentName}();
      
      // Assert
      expect(instance).toBeDefined();
      expect(instance.{property}).toBe({defaultValue});
    });
    
    test('should initialize with provided options', () => {
      // Arrange
      const options = {
        {property}: 'custom value'
      };
      
      // Act
      const instance = new {ComponentName}(options);
      
      // Assert
      expect(instance.{property}).toBe('custom value');
    });
  });
  
  describe('{method}', () => {
    test('should return expected result with valid input', () => {
      // Arrange
      const input = testData.validInput;
      const expectedResult = { result: 'success' };
      
      // Act
      const result = component.{method}(input);
      
      // Assert
      expect(result).toEqual(expectedResult);
      expect(mockDependency).toHaveBeenCalledWith(input);
      expect(mockDependency).toHaveBeenCalledTimes(1);
    });
    
    test('should throw error with invalid input', () => {
      // Arrange
      const input = testData.invalidInput;
      
      // Act & Assert
      expect(() => {
        component.{method}(input);
      }).toThrow('Invalid input');
    });
    
    test('should handle edge cases gracefully', () => {
      // Arrange
      const input = testData.edgeCase;
      
      // Act
      const result = component.{method}(input);
      
      // Assert
      expect(result).toBeDefined();
      expect(result.status).toBe('handled');
    });
    
    test('should handle async operations correctly', async () => {
      // Arrange
      const input = testData.validInput;
      mockDependency.mockResolvedValue({ async: 'result' });
      
      // Act
      const result = await component.{asyncMethod}(input);
      
      // Assert
      expect(result).toEqual({ async: 'result' });
      expect(mockDependency).toHaveBeenCalledWith(input);
    });
    
    test('should handle async errors correctly', async () => {
      // Arrange
      const input = testData.validInput;
      const error = new Error('Async operation failed');
      mockDependency.mockRejectedValue(error);
      
      // Act & Assert
      await expect(component.{asyncMethod}(input)).rejects.toThrow('Async operation failed');
    });
  });
  
  describe('property getters and setters', () => {
    test('should get property value correctly', () => {
      // Arrange
      component._internalProperty = 'test value';
      
      // Act
      const value = component.{property};
      
      // Assert
      expect(value).toBe('test value');
    });
    
    test('should set property value correctly', () => {
      // Arrange
      const newValue = 'new value';
      
      // Act
      component.{property} = newValue;
      
      // Assert
      expect(component._internalProperty).toBe(newValue);
    });
  });
  
  describe('event handling', () => {
    test('should emit events correctly', (done) => {
      // Arrange
      const eventData = { message: 'test event' };
      
      component.on('testEvent', (data) => {
        // Assert
        expect(data).toEqual(eventData);
        done();
      });
      
      // Act
      component.emit('testEvent', eventData);
    });
  });
  
  describe('mocking examples', () => {
    test('should work with mocked timers', () => {
      // Enable fake timers
      jest.useFakeTimers();
      
      // Arrange
      const callback = jest.fn();
      component.delayedOperation(callback, 1000);
      
      // Act - advance time
      jest.advanceTimersByTime(1000);
      
      // Assert
      expect(callback).toHaveBeenCalled();
      
      // Cleanup
      jest.useRealTimers();
    });
    
    test('should work with mocked modules', () => {
      // Mock entire module
      jest.mock('../external-module', () => ({
        externalFunction: jest.fn().mockReturnValue('mocked value')
      }));
      
      const { externalFunction } = require('../external-module');
      
      // Act
      const result = component.useExternal();
      
      // Assert
      expect(result).toBe('mocked value');
      expect(externalFunction).toHaveBeenCalled();
    });
  });
  
  describe('snapshot testing', () => {
    test('should match snapshot', () => {
      // Arrange
      const input = testData.validInput;
      
      // Act
      const result = component.{method}(input);
      
      // Assert
      expect(result).toMatchSnapshot();
    });
  });
  
  describe('performance testing', () => {
    test('should complete within performance limits', () => {
      // Arrange
      const largeInput = generateLargeTestData(1000);
      const startTime = performance.now();
      
      // Act
      component.{method}(largeInput);
      const duration = performance.now() - startTime;
      
      // Assert
      expect(duration).toBeLessThan(100); // milliseconds
    });
  });
});

// Mocha/Chai example (alternative)
const { expect } = require('chai');
const sinon = require('sinon');

describe('{ComponentName} (Mocha/Chai)', function() {
  let component;
  let mockDependency;
  
  beforeEach(function() {
    mockDependency = sinon.stub();
    component = new {ComponentName}({
      dependency: mockDependency
    });
  });
  
  afterEach(function() {
    sinon.restore();
  });
  
  it('should initialize correctly', function() {
    expect(component).to.exist;
    expect(component.{property}).to.equal({defaultValue});
  });
  
  it('should handle method call with valid input', function() {
    // Arrange
    const input = { key: 'value' };
    const expectedResult = { result: 'success' };
    
    // Act
    const result = component.{method}(input);
    
    // Assert
    expect(result).to.deep.equal(expectedResult);
    expect(mockDependency.calledOnce).to.be.true;
    expect(mockDependency.calledWith(input)).to.be.true;
  });
});

// Helper functions
function generateLargeTestData(size) {
  return Array.from({ length: size }, (_, i) => ({
    id: i,
    value: `value_${i}`
  }));
}

// Custom matchers (Jest)
expect.extend({
  toBeValidResponse(received) {
    const pass = 
      received !== null &&
      typeof received === 'object' &&
      'status' in received &&
      'data' in received;
    
    return {
      pass,
      message: () => pass
        ? `expected ${received} not to be a valid response`
        : `expected ${received} to be a valid response with status and data properties`
    };
  }
});

// Usage of custom matcher
test('should return valid response format', () => {
  const result = component.{method}();
  expect(result).toBeValidResponse();
});