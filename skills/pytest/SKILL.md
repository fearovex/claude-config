---
name: pytest
description: >
  Pytest testing patterns for Python: fixtures, mocking, parametrize, async tests.
  Trigger: When writing Python tests, using pytest, mocking dependencies, or testing async code.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
format: reference
---

## When to Use

**Triggers**: When writing Python tests, using pytest, mocking dependencies, or testing async code.

Load when: writing Python tests with pytest, setting up fixtures, mocking external dependencies, or testing async functions.

## Critical Patterns

### Pattern 1: Organized test classes

```python
import pytest

class TestUserService:
    def test_create_user_successfully(self, user_service, valid_user_data):
        result = user_service.create(valid_user_data)
        assert result.id is not None
        assert result.name == valid_user_data["name"]

    def test_create_user_with_duplicate_email_raises(self, user_service, existing_user):
        with pytest.raises(ValueError, match="Email already exists"):
            user_service.create({"email": existing_user.email, "name": "Other"})

    def test_get_user_not_found_raises(self, user_service):
        with pytest.raises(LookupError):
            user_service.get("nonexistent-id")
```

### Pattern 2: Fixtures with scope and yield

```python
import pytest
from myapp.db import Database

@pytest.fixture(scope="module")  # Shared across the entire module
def db():
    database = Database.create_test_db()
    yield database  # Setup
    database.cleanup()  # Teardown automático

@pytest.fixture(scope="function")  # New for each test (default)
def user_service(db):
    return UserService(db)

@pytest.fixture
def valid_user_data():
    return {"name": "Juan", "email": "juan@example.com"}
```

### Pattern 3: conftest.py for shared fixtures

```python
# tests/conftest.py — accessible in all tests
import pytest
from myapp import create_app
from myapp.db import db as _db

@pytest.fixture(scope="session")
def app():
    app = create_app(testing=True)
    return app

@pytest.fixture(scope="session")
def db(app):
    with app.app_context():
        _db.create_all()
        yield _db
        _db.drop_all()

@pytest.fixture
def client(app):
    return app.test_client()
```

## Code Examples

### Mocking with unittest.mock

```python
from unittest.mock import MagicMock, patch

class TestEmailService:
    def test_send_welcome_email(self, user):
        with patch('myapp.email.smtp_client') as mock_smtp:
            mock_smtp.send.return_value = True
            result = email_service.send_welcome(user)
            assert result is True
            mock_smtp.send.assert_called_once_with(
                to=user.email,
                subject="Welcome!"
            )

    def test_email_failure_raises(self, user):
        with patch('myapp.email.smtp_client') as mock_smtp:
            mock_smtp.send.side_effect = ConnectionError("SMTP unavailable")
            with pytest.raises(EmailError):
                email_service.send_welcome(user)
```

### Parametrize

```python
@pytest.mark.parametrize("email,expected", [
    ("valid@example.com", True),
    ("also.valid+tag@domain.co", True),
    ("invalid-email", False),
    ("missing@tld", False),
    ("", False),
    (None, False),
])
def test_email_validation(email, expected):
    assert validate_email(email) == expected


@pytest.mark.parametrize("role,can_delete", [
    ("admin", True),
    ("user", False),
    ("guest", False),
])
def test_delete_permission(role, can_delete, make_user):
    user = make_user(role=role)
    assert user.can_delete_posts() == can_delete
```

### Markers and selective execution

```python
import pytest

@pytest.mark.slow
def test_heavy_computation():
    result = run_heavy_task()
    assert result > 0

@pytest.mark.integration
def test_database_roundtrip(db):
    user = db.create({"name": "Test"})
    found = db.get(user.id)
    assert found.name == "Test"

@pytest.mark.skip(reason="Feature not implemented yet")
def test_future_feature():
    pass

@pytest.mark.skipif(
    condition=sys.platform == "win32",
    reason="Not supported on Windows"
)
def test_unix_only():
    pass
```

```ini
# pytest.ini or pyproject.toml
[pytest]
markers =
    slow: marks tests as slow
    integration: marks tests as integration tests
```

```bash
# Run only fast tests (exclude slow)
pytest -m "not slow"

# Run only integration
pytest -m integration
```

### Async tests

```python
import pytest
import pytest_asyncio

@pytest.mark.asyncio
async def test_async_user_creation():
    service = AsyncUserService()
    user = await service.create({"name": "Test", "email": "test@example.com"})
    assert user.id is not None

@pytest_asyncio.fixture
async def async_db():
    db = await AsyncDatabase.connect()
    yield db
    await db.close()
```

### Factory fixtures

```python
@pytest.fixture
def make_user(db):
    """Factory fixture to create users with custom values."""
    created = []

    def _make_user(**kwargs):
        defaults = {
            "name": "Test User",
            "email": f"test_{len(created)}@example.com",
            "role": "user",
        }
        user = db.users.create({**defaults, **kwargs})
        created.append(user)
        return user

    yield _make_user

    # Cleanup
    for user in created:
        db.users.delete(user.id)
```

## Anti-Patterns

### ❌ Tests without assertions

```python
# ❌ What is being verified?
def test_create_user():
    user_service.create({"name": "Juan"})

# ✅ Clear assertion
def test_create_user():
    user = user_service.create({"name": "Juan"})
    assert user.id is not None
    assert user.name == "Juan"
```

### ❌ Interdependent tests

```python
# ❌ Test 2 depends on the state of Test 1
def test_1_create():
    global created_id
    user = service.create(data)
    created_id = user.id

def test_2_get():
    user = service.get(created_id)  # Fails if test_1 didn't run

# ✅ Each test is independent with fixtures
def test_get_user(make_user):
    user = make_user()
    found = service.get(user.id)
    assert found.id == user.id
```

## Quick Reference

| Task | Command / Pattern |
|------|-------------------|
| Run all | `pytest -v` |
| By name | `pytest -k "user"` |
| With coverage | `pytest --cov=src --cov-report=html` |
| Parallel | `pytest -n auto` |
| Only failures | `pytest --lf` |
| Stop at first failure | `pytest -x` |
| Custom marker | `@pytest.mark.name` |
| Expected exception | `pytest.raises(ValueError, match="pattern")` |
| Async test | `@pytest.mark.asyncio` |
| Fixture scope | `scope="function|class|module|session"` |

## Rules

- Fixtures are the required mechanism for test setup and dependency injection — never use `setUp`/`tearDown` class methods (that is unittest style)
- Use `@pytest.mark.parametrize` for data-driven tests; copy-pasted test functions that differ only in input values are a duplication anti-pattern
- Mock external dependencies (HTTP, DB, filesystem) at the boundary using `pytest-mock` or `unittest.mock.patch`; never let tests hit real external services
- Async tests require `@pytest.mark.asyncio`; forgetting the marker causes the test to pass without actually executing the coroutine
- Scope fixtures correctly (`function`, `module`, `session`) — wide-scope fixtures that mutate shared state cause test order dependencies
