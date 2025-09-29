# Error Patterns Library

## Overview

This library contains common error patterns encountered during development, along with their solutions and best practices for handling them. This resource helps AI agents and developers quickly identify and resolve issues.

## Structure

```
error-patterns/
├── README.md                 # This file
├── index.json               # Error pattern index
├── categories/              # Error patterns by category
│   ├── syntax/             # Syntax errors
│   ├── runtime/            # Runtime errors
│   ├── logic/              # Logic errors
│   ├── integration/        # Integration errors
│   └── performance/        # Performance issues
└── languages/              # Language-specific patterns
    ├── python/
    ├── javascript/
    ├── typescript/
    └── general/
```

## Error Pattern Format

Each error pattern follows this structure:

```json
{
  "id": "unique-error-id",
  "name": "Error Pattern Name",
  "category": "syntax|runtime|logic|integration|performance",
  "languages": ["python", "javascript", "general"],
  "description": "Brief description of the error",
  "symptoms": [
    "Error message or behavior",
    "Stack trace pattern"
  ],
  "causes": [
    "Common cause 1",
    "Common cause 2"
  ],
  "solutions": [
    {
      "description": "Solution description",
      "code": "Example code fix",
      "preventive": true
    }
  ],
  "related": ["related-error-id-1", "related-error-id-2"],
  "tags": ["async", "type-error", "null-reference"],
  "severity": "low|medium|high|critical"
}
```

## Usage

### For AI Agents

1. **Error Detection**: When encountering an error, search the pattern library:
   ```bash
   # Search by error message
   grep -r "error message" .claude/shared/error-patterns/

   # Search by category
   ls .claude/shared/error-patterns/categories/runtime/
   ```

2. **Pattern Matching**: Compare the error symptoms with patterns in the library

3. **Solution Application**: Apply the recommended solutions in order of relevance

### For Developers

1. **Browse by Category**: Navigate to the relevant category folder
2. **Search by Language**: Check language-specific patterns
3. **Add New Patterns**: Follow the format above to contribute new patterns

## Contributing New Patterns

When adding a new error pattern:

1. Identify the appropriate category and language
2. Create a JSON file following the standard format
3. Update the index.json file
4. Include real-world examples and tested solutions
5. Tag appropriately for easy discovery

## Best Practices

1. **Be Specific**: Include exact error messages and stack traces
2. **Provide Context**: Explain when and why the error occurs
3. **Test Solutions**: Ensure all solutions are verified
4. **Cross-Reference**: Link related patterns for comprehensive coverage
5. **Keep Updated**: Review and update patterns as languages evolve

## AI Learning Integration

This library is designed to help AI agents:

- Learn from past errors
- Apply solutions consistently
- Prevent common mistakes
- Improve debugging efficiency

The structured format allows for easy parsing and pattern matching by AI systems.
