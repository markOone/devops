#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Будь ласка, запустіть скрипт через sudo: sudo bash deploy.sh"
  exit
fi

echo "Починаємо розгортання..."

apt-get update
apt-get install -y postgresql postgresql-contrib python3 python3-dev python3-venv python3-pip nginx git curl libpq-dev build-essential

useradd -m -s /bin/bash -G sudo student 2>/dev/null || echo "Користувач student вже існує"
echo "student:studentpass" | chpasswd

useradd -m -s /bin/bash -G sudo teacher 2>/dev/null || echo "Користувач teacher вже існує"
echo "teacher:12345678" | chpasswd
chage -d 0 teacher

useradd -r -s /usr/sbin/nologin app 2>/dev/null || echo "Користувач app вже існує"

useradd -m -s /bin/bash operator 2>/dev/null || echo "Користувач operator вже існує"
echo "operator:12345678" | chpasswd
chage -d 0 operator

cat <<EOT > /etc/sudoers.d/operator
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl start mywebapp.service, /usr/bin/systemctl stop mywebapp.service, /usr/bin/systemctl restart mywebapp.service, /usr/bin/systemctl status mywebapp.service, /usr/bin/systemctl reload nginx
EOT

sudo -u postgres psql -c "CREATE DATABASE taskdb;" 2>/dev/null || echo "БД вже існує"
sudo -u postgres psql -c "CREATE USER appuser WITH ENCRYPTED PASSWORD 'apppass';" 2>/dev/null || echo "Користувач БД вже існує"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE taskdb TO appuser;"
sudo -u postgres psql -d taskdb -c "GRANT ALL ON SCHEMA public TO appuser;"

mkdir -p /etc/mywebapp
cat <<EOF > /etc/mywebapp/config.json
{
  "dbname": "taskdb",
  "user": "appuser",
  "password": "apppass",
  "host": "127.0.0.1"
}
EOF
chown -R app:app /etc/mywebapp

APP_DIR="/opt/mywebapp"
rm -rf $APP_DIR  
git clone https://github.com/markOone/devops $APP_DIR

python3 -m venv $APP_DIR/venv
$APP_DIR/venv/bin/pip install -r $APP_DIR/requirements.txt
chown -R app:app $APP_DIR

cat <<EOF > /etc/systemd/system/mywebapp.socket
[Unit]
Description=MyWebApp Systemd Socket

[Socket]
ListenStream=127.0.0.1:3000

[Install]
WantedBy=sockets.target
EOF

cat <<EOF > /etc/systemd/system/mywebapp.service
[Unit]
Description=MyWebApp Task Tracker
After=network.target postgresql.service
Requires=mywebapp.socket

[Service]
User=app
WorkingDirectory=$APP_DIR
ExecStartPre=$APP_DIR/venv/bin/python $APP_DIR/init_db.py
ExecStart=$APP_DIR/venv/bin/gunicorn app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mywebapp.socket
systemctl start mywebapp.socket
systemctl enable mywebapp.service
systemctl restart mywebapp.service

rm -f /etc/nginx/sites-enabled/default
cat <<EOF > /etc/nginx/sites-available/mywebapp
server {
    listen 80;
    server_name _;
    access_log /var/log/nginx/mywebapp_access.log;

    location = / {
        proxy_pass http://127.0.0.1:3000;
    }
    location /tasks {
        proxy_pass http://127.0.0.1:3000;
    }
    location /health {
        proxy_pass http://127.0.0.1:3000;
    }
    location / {
        return 404;
    }
}
EOF
ln -s /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/ 2>/dev/null
systemctl restart nginx

echo "7" > /home/student/gradebook
chown student:student /home/student/gradebook

usermod -L mark

echo "Готово! Система налаштована і запущена через Socket Activation."