from flask import Blueprint, request
from app.db import db
from app.models import Item
from datetime import datetime, timezone

items = Blueprint("items", __name__)

def html_page(title, body):
    return "<!DOCTYPE html><html><head><title>" + title + "</title></head><body>" + body + "</body></html>"

@items.route("/items", methods=['GET'])
def get_items():
    all_items = Item.query.all()
    accept = request.headers.get('Accept', 'application/json')

    if 'text/html' in accept:
        rows = ""
        for i in all_items:
            rows += "<tr><td>" + str(i.id) + "</td><td>" + i.name + "</td></tr>"
        body = "<table border='1'><tr><th>id</th><th>name</th></tr>" + rows + "</table>"
        return html_page("Inventory", body), 200
    
    result = []
    for i in all_items:
        result.append({"id": i.id, "name": i.name})
    return {"items": result}, 200

@items.route("/items", methods=['POST'])
def create_item():
    data = request.get_json()
    name = data.get('name')
    quantity = data.get('quantity')

    if not name or quantity is None:
        return {"error": "name and quantity are required"}, 400

    new_item = Item(name=name, quantity=quantity, created_at=datetime.now(timezone.utc))
    db.session.add(new_item)
    db.session.commit()
    return {"id": new_item.id}, 201

@items.route("/items/<int:id>", methods=['GET'])
def get_item(id):
    item = Item.query.get(id)
    if item is None:
        return {"error": "Item not found"}, 404

    accept = request.headers.get('Accept', 'application/json')

    if 'text/html' in accept:
        body = "<h2>Item details</h2>"
        body += "<table border='1'>"
        body += "<tr><th>id</th><td>" + str(item.id) + "</td></tr>"
        body += "<tr><th>name</th><td>" + item.name + "</td></tr>"
        body += "<tr><th>quantity</th><td>" + str(item.quantity) + "</td></tr>"
        body += "<tr><th>created_at</th><td>" + str(item.created_at) + "</td></tr>"
        body += "</table>"
        return html_page("Item details", body), 200

    return {
        "id": item.id,
        "name": item.name,
        "quantity": item.quantity,
        "created_at": str(item.created_at)
    }, 200

items.route("/", methods=['GET'])
def root():
    body = """
        <h2>Available endpoints</h2>
        <ul>
            <li>GET /items — list all items</li>
            <li>POST /items — create new item</li>
            <li>GET /items/&lt;id&gt; — get item by id</li>
        </ul>
    """
    return html_page("Inventory API", body), 200