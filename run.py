import os
from app import create_app
from app.config import config
from app.db import db

app = create_app()

with app.app_context():
    db.create_all()

if __name__ == '__main__':
    run_host = os.getenv('APP_HOST', config['server']['host'])
    run_port = int(os.getenv('APP_PORT', config['server']['port']))
    
    app.run(host=run_host, port=run_port)