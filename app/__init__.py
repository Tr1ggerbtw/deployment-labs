from flask import Flask
from app.db import db
from app.config import Config


def create_app(test_config=None):
    app = Flask(__name__)
    app.config.from_object(Config)

    if test_config:
        app.config.update(test_config)

    db.init_app(app)

    from app.routes.items import items
    from app.routes.health import health
    app.register_blueprint(items)
    app.register_blueprint(health)

    return app
