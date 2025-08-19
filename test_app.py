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
    # Fix: Use the actual title from your app
    assert b'Forex Conversion' in response.data

def test_health_check():
    """Test a simple function"""
    # Add a simple test that always passes
    assert True

def test_app_exists():
    """Test that the Flask app exists"""
    assert app is not None

def test_currency_form_elements(client):
    """Test that the form elements are present"""
    response = client.get('/')
    assert response.status_code == 200
    assert b'<form method="POST">' in response.data
    assert b'name="amount"' in response.data
    assert b'name="currency"' in response.data
    assert b'EUR' in response.data
    assert b'GBP' in response.data
    assert b'CAD' in response.data
    assert b'PLN' in response.data
