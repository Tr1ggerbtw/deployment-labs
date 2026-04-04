from app import create_app
from app.db import db
from app.models import Item

app = create_app()

with app.app_context():
    db.create_all()