import yaml

def load_config():
    path="config.yaml" # for now like that later change to /etc/webmyapp/
    with open(path) as f:
        return yaml.safe_load(f)
    
config = load_config()
db_cfg = config['database']

class Config:
    SQLALCHEMY_DATABASE_URI = f"postgresql://{db_cfg['user']}:{db_cfg['password']}@{db_cfg['host']}:{db_cfg['port']}/{db_cfg['name']}"
    SQLALCHEMY_TRACK_MODIFICATIONS = False