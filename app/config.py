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
    raise FileNotFoundError("config.yaml not found")
    
config = load_config()
db_cfg = config['database']

class Config:
    SQLALCHEMY_DATABASE_URI = f"postgresql://{db_cfg['user']}:{db_cfg['password']}@{db_cfg['host']}:{db_cfg['port']}/{db_cfg['name']}"
    SQLALCHEMY_TRACK_MODIFICATIONS = False
