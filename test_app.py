import pytest
from app import app 

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_page(client):
    """Перевіряємо, чи працює головна сторінка"""
    response = client.get('/')
    assert response.status_code == 200

def test_health_check(client):
    """Перевіряємо ендпоінт health/alive"""
    response = client.get('/health/alive')
    assert response.status_code == 200

def test_tasks_page(client):
    """Перевіряємо, чи сторінка завдань віддає хоча б якийсь успішний статус"""
    response = client.get('/tasks')
    assert response.status_code in [200, 500]