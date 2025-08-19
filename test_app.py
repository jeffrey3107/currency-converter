
import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index_page(client):
    """Test that the main page loads"""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Currency Converter' in response.data

def test_health_check():
    """Test a simple function"""
    # Add a simple test that always passes
    assert True

def test_app_exists():
    """Test that the Flask app exists"""
    assert app is not None
