#!/bin/bash
set -e

apt-get update
apt-get install -y python3 python3-pip python3-venv nginx postgresql postgresql-contrib

useradd -r -s /bin/false app 

for user in student teacher; 
do
    useradd -m -s /bin/bash $user
    echo "$user:12345678" | chpasswd
    usermod -aG sudo $user
    passwd -e $user
done

useradd -m -g operator -s /bin/bash operator
echo "operator:12345678" | chpasswd
passwd -e operator

cat > /etc/sudoers.d/operator << EOF
operator ALL=(ALL) NOPASSWD: /bin/systemctl start mywebapp, /bin/systemctl stop mywebapp, /bin/systemctl restart mywebapp, /bin/systemctl status mywebapp, /bin/systemctl reload nginx
EOF
chmod 440 /etc/sudoers.d/operator

sudo -u postgres psql -c "CREATE DATABASE inventory;"
sudo -u postgres psql -c "CREATE USER app WITH ENCRYPTED PASSWORD 'password123';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE inventory TO app;"
sudo -u postgres psql -d inventory -c "GRANT ALL ON SCHEMA public TO app;"

mkdir -p /opt/mywebapp
cp -r ./* /opt/mywebapp/
chown -R app:app /opt/mywebapp

mkdir -p /etc/mywebapp
cat > /etc/mywebapp/config.yaml << EOF
server:
  host: 127.0.0.1
  port: 5200
database:
  host: 127.0.0.1
  port: 5432
  name: inventory
  user: app
  password: password123
EOF
chown -R app:app /etc/mywebapp

python3 -m venv /opt/mywebapp/venv
/opt/mywebapp/venv/bin/pip install -r /opt/mywebapp/requirements.txt
/opt/mywebapp/venv/bin/pip install gunicorn

cp /opt/mywebapp/deploy/mywebapp.service /etc/systemd/system/mywebapp.service
systemctl daemon-reload

systemctl enable mywebapp
systemctl start mywebapp

cp /opt/mywebapp/deploy/nginx.conf /etc/nginx/sites-available/mywebapp
ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

echo "11" > /home/student/gradebook
chown student:student /home/student/gradebook

passwd -l ubuntu || true
