def validate_user(email: str, password: str):
    """Minimal stub used by tests via monkeypatch/patch.

    Returns a fake user dict for the well-known test credentials,
    otherwise returns None.
    """
    if email == 'test@haroonnet.com' and password == 'test123':
        return {
            'id': 1,
            'email': email,
            'firstName': 'Test',
            'lastName': 'User',
            'roles': ['admin'],
            'permissions': ['users.view', 'users.create'],
        }
    return None

