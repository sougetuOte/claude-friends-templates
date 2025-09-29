# User Service Design

## Interface Specification

```typescript
interface UserService {
  getUser(id: string): User;
  createUser(userData: UserData): User;
  updateUser(id: string, userData: Partial<UserData>): User;
  deleteUser(id: string): void;
}
```

## Methods

### getUser
- **Function**: Retrieve user by ID
- **Parameters**: id (string)
- **Returns**: User object

### createUser
- **Function**: Create new user
- **Parameters**: userData (UserData)
- **Returns**: Created user object

## Design Principles
- Follow single responsibility principle
- Use dependency injection pattern
- Implement proper error handling
