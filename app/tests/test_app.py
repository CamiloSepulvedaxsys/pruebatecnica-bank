"""Unit tests for Flask application."""
from unittest.mock import patch

import pytest
from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    app.config["WTF_CSRF_ENABLED"] = False
    with app.test_client() as client:
        yield client


def test_index(client):
    response = client.get("/")
    assert response.status_code == 200
    data = response.get_json()
    assert data["message"] == "Hello, World!"
    assert data["status"] == "running"


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "healthy"


@patch("app.app.run")
def test_main_entrypoint(mock_run):
    from app import main
    main()
    mock_run.assert_called_once_with(host="127.0.0.1", port=8000)
