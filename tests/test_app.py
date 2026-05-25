import pytest
from unittest.mock import patch, MagicMock
from app import create_app
from app.db import db as _db

@pytest.fixture(scope="session")
def app():
    test_config = {
        "TESTING": True,
        "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
        "SQLALCHEMY_TRACK_MODIFICATIONS": False,
        "WTF_CSRF_ENABLED": False,
    }
    
    _app = create_app(test_config)

    with _app.app_context():
        _db.create_all()         
        yield _app
        _db.drop_all()

@pytest.fixture()
def client(app):
    return app.test_client()


@pytest.fixture(autouse=True)
def clean_items(app):
    from app.models import Item
    with app.app_context():
        _db.session.query(Item).delete()
        _db.session.commit()
    yield

def _create_item(client, name="Test Item", quantity=10):
    resp = client.post(
        "/items",
        json={"name": name, "quantity": quantity},
        content_type="application/json",
    )
    return resp


# Health endpoints

class TestHealthAlive:

    def test_returns_200(self, client):
        resp = client.get("/health/alive")
        assert resp.status_code == 200

    def test_returns_ok_text(self, client):
        resp = client.get("/health/alive")
        assert resp.data == b"OK"


class TestHealthReady:
    def test_returns_200_when_db_ok(self, client):
        resp = client.get("/health/ready")
        assert resp.status_code == 200

    def test_returns_ok_text_when_db_ok(self, client):
        resp = client.get("/health/ready")
        assert resp.data == b"OK"

    def test_returns_500_when_db_fails(self, app, client):
        from app.db import db

        with patch.object(db.session, "execute", side_effect=Exception("DB down")):
            resp = client.get("/health/ready")
        assert resp.status_code == 500

# Root endpoint

class TestRoot:

    def test_returns_200(self, client):
        resp = client.get("/")
        assert resp.status_code == 200

    def test_contains_html(self, client):
        resp = client.get("/")
        text = resp.data.decode()
        assert "<!DOCTYPE html>" in text

    def test_contains_endpoints_list(self, client):
        resp = client.get("/")
        text = resp.data.decode()
        assert "/items" in text


# GET /items

class TestGetItems:

    def test_empty_list_returns_200(self, client):
        resp = client.get("/items")
        assert resp.status_code == 200

    def test_empty_list_json(self, client):
        resp = client.get("/items", headers={"Accept": "application/json"})
        data = resp.get_json()
        assert data == {"items": []}

    def test_returns_created_item(self, client):
        _create_item(client, name="Laptop", quantity=5)
        resp = client.get("/items", headers={"Accept": "application/json"})
        data = resp.get_json()
        assert len(data["items"]) == 1
        assert data["items"][0]["name"] == "Laptop"

    def test_html_response(self, client):
        _create_item(client, name="Monitor", quantity=2)
        resp = client.get("/items", headers={"Accept": "text/html"})
        text = resp.data.decode()
        assert "<table" in text
        assert "Monitor" in text

    def test_multiple_items(self, client):
        _create_item(client, name="Item A", quantity=1)
        _create_item(client, name="Item B", quantity=2)
        resp = client.get("/items", headers={"Accept": "application/json"})
        data = resp.get_json()
        assert len(data["items"]) == 2


# POST /items

class TestCreateItem:
    def test_create_returns_201(self, client):
        resp = _create_item(client)
        assert resp.status_code == 201

    def test_create_returns_id(self, client):
        resp = _create_item(client)
        data = resp.get_json()
        assert "id" in data
        assert isinstance(data["id"], int)

    def test_create_missing_name(self, client):
        resp = client.post("/items", json={"quantity": 5})
        assert resp.status_code == 400
        assert "error" in resp.get_json()

    def test_create_missing_quantity(self, client):
        resp = client.post("/items", json={"name": "Chair"})
        assert resp.status_code == 400

    def test_create_empty_body(self, client):
        resp = client.post("/items", json={})
        assert resp.status_code == 400

    def test_zero_quantity_allowed(self, client):
        resp = _create_item(client, name="Empty shelf", quantity=0)
        assert resp.status_code == 201


# GET /items/<id>

class TestGetItemById:
    def test_get_existing_item_json(self, client):
        create_resp = _create_item(client, name="Router", quantity=3)
        item_id = create_resp.get_json()["id"]

        resp = client.get(f"/items/{item_id}", headers={"Accept": "application/json"})
        assert resp.status_code == 200
        data = resp.get_json()
        assert data["name"] == "Router"
        assert data["quantity"] == 3

    def test_get_existing_item_html(self, client):
        create_resp = _create_item(client, name="Switch", quantity=4)
        item_id = create_resp.get_json()["id"]

        resp = client.get(f"/items/{item_id}", headers={"Accept": "text/html"})
        assert resp.status_code == 200
        text = resp.data.decode()
        assert "Switch" in text
        assert "<table" in text

    def test_get_nonexistent_item_404(self, client):
        resp = client.get("/items/99999")
        assert resp.status_code == 404

    def test_get_nonexistent_item_error_message(self, client):
        resp = client.get("/items/99999")
        data = resp.get_json()
        assert "error" in data

    def test_response_contains_created_at(self, client):
        create_resp = _create_item(client, name="Cable", quantity=10)
        item_id = create_resp.get_json()["id"]

        resp = client.get(f"/items/{item_id}", headers={"Accept": "application/json"})
        data = resp.get_json()
        assert "created_at" in data

    def test_full_crud_flow(self, client):
        create_resp = _create_item(client, name="Server", quantity=1)
        assert create_resp.status_code == 201
        item_id = create_resp.get_json()["id"]

        get_resp = client.get(
            f"/items/{item_id}", headers={"Accept": "application/json"}
        )
        assert get_resp.status_code == 200
        assert get_resp.get_json()["name"] == "Server"

        list_resp = client.get("/items", headers={"Accept": "application/json"})
        ids = [i["id"] for i in list_resp.get_json()["items"]]
        assert item_id in ids