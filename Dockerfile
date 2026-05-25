FROM python:3.12-slim
 
RUN useradd -r -s /bin/false app
 
WORKDIR /opt/mywebapp
 
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn
 
COPY . .
 
RUN chown -R app:app /opt/mywebapp
 
USER app
 
EXPOSE 5200
 
CMD ["sh", "-c", "python migrate.py && gunicorn --bind 0.0.0.0:5200 'run:app'"]
