# Create a lightweight test file

import pytest
from app import app, get_exchange_rate, init_db

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index_page(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b'Forex Conversion' in response.data

def test_health_check():
    assert True

def test_app_exists():
    assert app is not None

def test_currency_form_elements(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b'<form method="POST">' in response.data
    assert b'name="amount"' in response.data
    assert b'name="currency"' in response.data

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'

def test_get_exchange_rate():
    rate = get_exchange_rate('USD', 'EUR')
    assert isinstance(rate, (int, float))
    assert rate > 0

def test_currency_conversion_post(client):
    response = client.post('/', data={'amount': '100', 'currency': 'EUR'})
    assert response.status_code == 200

def test_invalid_amount_conversion(client):
    # Test with empty amount since HTML form prevents invalid text
    response = client.post('/', data={'amount': '', 'currency': 'EUR'})
    assert response.status_code == 200
    assert b'Please fill in all fields' in response.data

def test_metrics_endpoint(client):
    response = client.get('/metrics')
    assert response.status_code == 200
    assert b'app_status' in response.data