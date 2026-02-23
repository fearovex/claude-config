---
name: pytest
description: >
  Pytest testing patterns for Python: fixtures, mocking, parametrize, async tests.
  Trigger: When writing Python tests, using pytest, mocking dependencies, or testing async code.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: writing Python tests with pytest, setting up fixtures, mocking external dependencies, or testing async functions.

## Critical Patterns

### Pattern 1: Clases de test organizadas

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

### Pattern 2: Fixtures con scope y yield

```python
import pytest
from myapp.db import Database

@pytest.fixture(scope="module")  # Compartido en todo el módulo
def db():
    database = Database.create_test_db()
    yield database  # Setup
    database.cleanup()  # Teardown automático

@pytest.fixture(scope="function")  # Nuevo por cada test (default)
def user_service(db):
    return UserService(db)

@pytest.fixture
def valid_user_data():
    return {"name": "Juan", "email": "juan@example.com"}
```

### Pattern 3: conftest.py para fixtures compartidas

```python
# tests/conftest.py — accesible en todos los tests
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

### Mocking con unittest.mock

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

### Markers y ejecución selectiva

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
# pytest.ini o pyproject.toml
[pytest]
markers =
    slow: marks tests as slow
    integration: marks tests as integration tests
```

```bash
# Correr solo tests rápidos (excluir slow)
pytest -m "not slow"

# Correr solo integration
pytest -m integration
```

### Tests asíncronos

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

### Fixtures de factory

```python
@pytest.fixture
def make_user(db):
    """Factory fixture para crear usuarios con valores custom."""
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

### ❌ Tests sin assertions

```python
# ❌ ¿Qué se está verificando?
def test_create_user():
    user_service.create({"name": "Juan"})

# ✅ Assertion clara
def test_create_user():
    user = user_service.create({"name": "Juan"})
    assert user.id is not None
    assert user.name == "Juan"
```

### ❌ Tests interdependientes

```python
# ❌ Test 2 depende del estado de Test 1
def test_1_create():
    global created_id
    user = service.create(data)
    created_id = user.id

def test_2_get():
    user = service.get(created_id)  # Falla si test_1 no corrió

# ✅ Cada test es independiente con fixtures
def test_get_user(make_user):
    user = make_user()
    found = service.get(user.id)
    assert found.id == user.id
```

## Quick Reference

| Task | Comando / Patrón |
|------|-----------------|
| Correr todos | `pytest -v` |
| Por nombre | `pytest -k "user"` |
| Con coverage | `pytest --cov=src --cov-report=html` |
| Paralelo | `pytest -n auto` |
| Solo fallos | `pytest --lf` |
| Detener al primer fallo | `pytest -x` |
| Marker custom | `@pytest.mark.nombre` |
| Exception esperada | `pytest.raises(ValueError, match="pattern")` |
| Async test | `@pytest.mark.asyncio` |
| Scope fixture | `scope="function|class|module|session"` |
