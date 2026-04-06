from flask import Blueprint
from sqlalchemy import text
from app.db import db

health = Blueprint("health", "__name__")

@health.route("/health/alive", methods=['GET'])
def check_alive():
    return "OK", 200

@health.route("/health/ready", methods=['GET'])
def check_ready():
    try:
        db.session.execute(text("SELECT 54"))
        return "OK", 200
    except Exception as e:
        return str(e), 500