import pytest
import sys
import os
import logging

# Set test environment before any imports
os.environ["TESTING"] = "1"

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from src.app import app, db

@pytest.fixture
def client():
    # Re-initialize database with SQLite
    with app.app_context():
        db.drop_all()
        db.create_all()
        yield app.test_client()
        db.drop_all()

def test_index(client):
    resp = client.get("/")
    assert resp.status_code == 200

def test_user_creation(client):
    resp = client.post("/users", json={"name": "Alice"})
    assert resp.status_code == 201
    data = resp.get_json()
    assert data["name"] == "Alice"
    assert "id" in data

def test_user_creation_and_retrieval(client):
    # Create a user
    resp = client.post("/users", json={"name": "Bob"})
    assert resp.status_code == 201
    created_user = resp.get_json()
    assert created_user["name"] == "Bob"
    user_id = created_user["id"]

    # Get all users and verify the created user is in the list
    resp = client.get("/users")
    assert resp.status_code == 200
    users = resp.get_json()
    assert len(users) == 1
    assert users[0]["name"] == "Bob"
    assert users[0]["id"] == user_id

def test_multiple_user_creation(client):
    # Create multiple users
    users_to_create = ["Charlie", "Diana", "Eve"]
    created_users = []

    for name in users_to_create:
        resp = client.post("/users", json={"name": name})
        assert resp.status_code == 201
        user_data = resp.get_json()
        assert user_data["name"] == name
        created_users.append(user_data)

    # Verify all users are stored
    resp = client.get("/users")
    assert resp.status_code == 200
    all_users = resp.get_json()
    assert len(all_users) == 3

    # Check each user exists
    user_names = [user["name"] for user in all_users]
    for name in users_to_create:
        assert name in user_names
