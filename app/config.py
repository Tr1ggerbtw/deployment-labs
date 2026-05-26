import yaml
import os


def load_config():
    paths = [
        "/etc/mywebapp/config.yaml",
        os.path.join(os.path.dirname(os.path.dirname(__file__)), "config.yaml")
    ]
    for path in paths:
        if os.path.exists(path):
            with open(path) as f:
                return yaml.safe_load(f)
    return {'database': {}}


config = load_config()
db_cfg = config.get('database', {})


class Config:
    user = os.getenv('DB_USER') or db_cfg.get('user', 'app')
    password = os.getenv('DB_PASSWORD') or db_cfg.get('password', 'password123')
    host = os.getenv('DB_HOST') or db_cfg.get('host', 'localhost')
    port = os.getenv('DB_PORT') or db_cfg.get('port', '5432')
    db_name = os.getenv('DB_NAME') or db_cfg.get('name', 'inventory')

    SQLALCHEMY_DATABASE_URI = os.getenv(
        'SQLALCHEMY_DATABASE_URI',
        f"postgresql://{user}:{password}@{host}:{port}/{db_name}"
    )

    SQLALCHEMY_TRACK_MODIFICATIONS = False
    