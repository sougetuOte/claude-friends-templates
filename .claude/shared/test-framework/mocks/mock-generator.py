#!/usr/bin/env python3
"""
Mock Generator Utility

This utility helps generate mock objects and test doubles for various testing scenarios.
"""

import json
import random
import string
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Union, Type
from abc import ABC, abstractmethod
import uuid


class MockGenerator:
    """Base class for generating mock data."""
    
    def __init__(self, seed: Optional[int] = None):
        """Initialize the generator with optional seed for reproducibility."""
        if seed:
            random.seed(seed)
    
    # Basic data generators
    def string(self, length: int = 10, prefix: str = "") -> str:
        """Generate a random string."""
        chars = string.ascii_letters + string.digits
        result = ''.join(random.choice(chars) for _ in range(length))
        return f"{prefix}{result}" if prefix else result
    
    def integer(self, min_val: int = 0, max_val: int = 100) -> int:
        """Generate a random integer."""
        return random.randint(min_val, max_val)
    
    def float(self, min_val: float = 0.0, max_val: float = 100.0, decimals: int = 2) -> float:
        """Generate a random float."""
        result = random.uniform(min_val, max_val)
        return round(result, decimals)
    
    def boolean(self, true_probability: float = 0.5) -> bool:
        """Generate a random boolean."""
        return random.random() < true_probability
    
    def uuid(self) -> str:
        """Generate a UUID."""
        return str(uuid.uuid4())
    
    def email(self, domain: str = "example.com") -> str:
        """Generate a random email address."""
        username = self.string(8, prefix="user_")
        return f"{username}@{domain}"
    
    def phone(self, format: str = "+1-XXX-XXX-XXXX") -> str:
        """Generate a random phone number."""
        result = format
        for _ in range(format.count('X')):
            result = result.replace('X', str(random.randint(0, 9)), 1)
        return result
    
    def date(self, start_date: Optional[datetime] = None, 
             end_date: Optional[datetime] = None) -> datetime:
        """Generate a random date between start and end."""
        if not start_date:
            start_date = datetime.now() - timedelta(days=365)
        if not end_date:
            end_date = datetime.now()
        
        time_between = end_date - start_date
        days_between = time_between.days
        random_days = random.randrange(days_between)
        return start_date + timedelta(days=random_days)
    
    def choice(self, choices: List[Any]) -> Any:
        """Select a random item from a list."""
        return random.choice(choices)
    
    def subset(self, items: List[Any], min_size: int = 1, 
               max_size: Optional[int] = None) -> List[Any]:
        """Select a random subset from a list."""
        if max_size is None:
            max_size = len(items)
        size = random.randint(min_size, min(max_size, len(items)))
        return random.sample(items, size)


class ObjectMockGenerator(MockGenerator):
    """Generate mock objects based on schemas."""
    
    def from_schema(self, schema: Dict[str, Any]) -> Dict[str, Any]:
        """Generate mock object from a schema definition."""
        result = {}
        
        for field, field_def in schema.items():
            if isinstance(field_def, dict):
                result[field] = self._generate_field(field_def)
            else:
                # Simple type definition
                result[field] = self._generate_by_type(field_def)
        
        return result
    
    def _generate_field(self, field_def: Dict[str, Any]) -> Any:
        """Generate a field value based on its definition."""
        field_type = field_def.get('type', 'string')
        
        if field_type == 'string':
            return self._generate_string_field(field_def)
        elif field_type == 'integer':
            return self.integer(
                field_def.get('min', 0),
                field_def.get('max', 100)
            )
        elif field_type == 'float':
            return self.float(
                field_def.get('min', 0.0),
                field_def.get('max', 100.0),
                field_def.get('decimals', 2)
            )
        elif field_type == 'boolean':
            return self.boolean(field_def.get('true_probability', 0.5))
        elif field_type == 'array':
            return self._generate_array_field(field_def)
        elif field_type == 'object':
            return self.from_schema(field_def.get('properties', {}))
        elif field_type == 'date':
            return self.date().isoformat()
        elif field_type == 'email':
            return self.email(field_def.get('domain', 'example.com'))
        elif field_type == 'uuid':
            return self.uuid()
        elif field_type == 'choice':
            return self.choice(field_def.get('choices', []))
        
        return None
    
    def _generate_string_field(self, field_def: Dict[str, Any]) -> str:
        """Generate a string field with constraints."""
        if 'pattern' in field_def:
            # For now, return a simple string
            # TODO: Implement regex-based generation
            return self.string(field_def.get('length', 10))
        elif 'enum' in field_def:
            return self.choice(field_def['enum'])
        else:
            return self.string(
                field_def.get('length', 10),
                field_def.get('prefix', '')
            )
    
    def _generate_array_field(self, field_def: Dict[str, Any]) -> List[Any]:
        """Generate an array field."""
        min_items = field_def.get('min_items', 1)
        max_items = field_def.get('max_items', 5)
        item_count = random.randint(min_items, max_items)
        
        items = []
        item_def = field_def.get('items', {'type': 'string'})
        
        for _ in range(item_count):
            if isinstance(item_def, dict):
                items.append(self._generate_field(item_def))
            else:
                items.append(self._generate_by_type(item_def))
        
        return items
    
    def _generate_by_type(self, type_name: str) -> Any:
        """Generate value by simple type name."""
        generators = {
            'string': lambda: self.string(),
            'int': lambda: self.integer(),
            'integer': lambda: self.integer(),
            'float': lambda: self.float(),
            'bool': lambda: self.boolean(),
            'boolean': lambda: self.boolean(),
            'uuid': lambda: self.uuid(),
            'email': lambda: self.email(),
            'date': lambda: self.date().isoformat(),
        }
        
        generator = generators.get(type_name, lambda: None)
        return generator()


class APIResponseMockGenerator(ObjectMockGenerator):
    """Generate mock API responses."""
    
    def success_response(self, data: Any = None, 
                        message: str = "Success") -> Dict[str, Any]:
        """Generate a successful API response."""
        return {
            "status": "success",
            "code": 200,
            "message": message,
            "data": data or {},
            "timestamp": datetime.now().isoformat()
        }
    
    def error_response(self, error_code: str = "ERROR_001",
                      message: str = "An error occurred",
                      status_code: int = 400) -> Dict[str, Any]:
        """Generate an error API response."""
        return {
            "status": "error",
            "code": status_code,
            "error_code": error_code,
            "message": message,
            "timestamp": datetime.now().isoformat()
        }
    
    def paginated_response(self, items: List[Any], 
                         page: int = 1,
                         per_page: int = 10,
                         total: Optional[int] = None) -> Dict[str, Any]:
        """Generate a paginated API response."""
        if total is None:
            total = len(items) * 10  # Simulate more items
        
        return {
            "status": "success",
            "code": 200,
            "data": {
                "items": items,
                "pagination": {
                    "page": page,
                    "per_page": per_page,
                    "total": total,
                    "total_pages": (total + per_page - 1) // per_page,
                    "has_next": page * per_page < total,
                    "has_prev": page > 1
                }
            },
            "timestamp": datetime.now().isoformat()
        }


class DatabaseMockGenerator(ObjectMockGenerator):
    """Generate mock database records."""
    
    def user(self, **overrides) -> Dict[str, Any]:
        """Generate a mock user record."""
        base = {
            "id": self.uuid(),
            "username": self.string(8, prefix="user_"),
            "email": self.email(),
            "first_name": self.choice(["John", "Jane", "Bob", "Alice", "Charlie"]),
            "last_name": self.choice(["Smith", "Johnson", "Williams", "Brown", "Jones"]),
            "is_active": self.boolean(0.9),
            "created_at": self.date().isoformat(),
            "updated_at": datetime.now().isoformat()
        }
        base.update(overrides)
        return base
    
    def product(self, **overrides) -> Dict[str, Any]:
        """Generate a mock product record."""
        base = {
            "id": self.uuid(),
            "name": f"Product {self.string(5)}",
            "description": f"Description for {self.string(10)}",
            "price": self.float(10.0, 1000.0),
            "stock": self.integer(0, 100),
            "category": self.choice(["Electronics", "Clothing", "Books", "Food", "Other"]),
            "is_available": self.boolean(0.8),
            "created_at": self.date().isoformat(),
            "updated_at": datetime.now().isoformat()
        }
        base.update(overrides)
        return base
    
    def order(self, user_id: Optional[str] = None, **overrides) -> Dict[str, Any]:
        """Generate a mock order record."""
        base = {
            "id": self.uuid(),
            "user_id": user_id or self.uuid(),
            "order_number": f"ORD-{self.integer(10000, 99999)}",
            "status": self.choice(["pending", "processing", "shipped", "delivered", "cancelled"]),
            "total": self.float(10.0, 1000.0),
            "items_count": self.integer(1, 10),
            "created_at": self.date().isoformat(),
            "updated_at": datetime.now().isoformat()
        }
        base.update(overrides)
        return base


class ServiceMockGenerator:
    """Generate mock services and dependencies."""
    
    @staticmethod
    def create_mock_service(interface: Type) -> Any:
        """Create a mock service that implements the given interface."""
        class MockService:
            def __init__(self):
                self.call_count = {}
                self.return_values = {}
                self.exceptions = {}
            
            def __getattr__(self, name):
                def mock_method(*args, **kwargs):
                    # Track calls
                    if name not in self.call_count:
                        self.call_count[name] = 0
                    self.call_count[name] += 1
                    
                    # Raise exception if configured
                    if name in self.exceptions:
                        raise self.exceptions[name]
                    
                    # Return configured value or default
                    if name in self.return_values:
                        return self.return_values[name]
                    
                    # Default returns
                    return {"status": "mocked", "method": name}
                
                return mock_method
            
            def configure_return(self, method_name: str, return_value: Any):
                """Configure return value for a method."""
                self.return_values[method_name] = return_value
            
            def configure_exception(self, method_name: str, exception: Exception):
                """Configure exception for a method."""
                self.exceptions[method_name] = exception
            
            def reset(self):
                """Reset all configurations and counters."""
                self.call_count.clear()
                self.return_values.clear()
                self.exceptions.clear()
        
        return MockService()


# Convenience functions
def generate_users(count: int = 10) -> List[Dict[str, Any]]:
    """Generate multiple mock users."""
    generator = DatabaseMockGenerator()
    return [generator.user() for _ in range(count)]


def generate_api_response(success: bool = True, data: Any = None) -> Dict[str, Any]:
    """Generate a mock API response."""
    generator = APIResponseMockGenerator()
    if success:
        return generator.success_response(data)
    else:
        return generator.error_response()


def generate_from_schema(schema: Dict[str, Any], count: int = 1) -> Union[Dict[str, Any], List[Dict[str, Any]]]:
    """Generate mock objects from a schema."""
    generator = ObjectMockGenerator()
    results = [generator.from_schema(schema) for _ in range(count)]
    return results[0] if count == 1 else results


# Example usage
if __name__ == "__main__":
    # Example schema
    user_schema = {
        "id": {"type": "uuid"},
        "name": {"type": "string", "length": 20},
        "email": {"type": "email"},
        "age": {"type": "integer", "min": 18, "max": 80},
        "is_premium": {"type": "boolean", "true_probability": 0.3},
        "tags": {
            "type": "array",
            "min_items": 1,
            "max_items": 5,
            "items": {"type": "choice", "choices": ["python", "javascript", "testing", "mock"]}
        }
    }
    
    # Generate mock data
    mock_user = generate_from_schema(user_schema)
    print("Mock User:", json.dumps(mock_user, indent=2))
    
    # Generate multiple users
    users = generate_users(3)
    print("\nMock Users:", json.dumps(users, indent=2))