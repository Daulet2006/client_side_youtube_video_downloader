#!/bin/bash

# ==========================================
# КОНФИГУРАЦИЯ
# ==========================================
DOMAIN="tude-load.duckdns.org"

echo "🚀 Начинаем полную автонастройку для $DOMAIN..."

# ==========================================
# 1. ГЕНЕРАЦИЯ nginx.conf
# ==========================================
echo "📝 Создаем nginx.conf..."
cat <<NGINX_CONF > nginx.conf
events {
    worker_connections 1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    # HTTP: Сервер для Let's Encrypt проверки + Редирект на HTTPS
    server {
        listen 80;
        server_name $DOMAIN;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://\$host\$request_uri;
        }
    }

    # HTTPS: Основной сервер
    server {
        listen 443 ssl;
        server_name $DOMAIN;

        ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        # Фронтенд (Nuxt)
        location / {
            proxy_pass http://frontend:3000;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Бэкенд API (обрати внимание на слэш в proxy_pass)
        location /api/ {
            proxy_pass http://backend:8000/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
NGINX_CONF

# ==========================================
# 2. ГЕНЕРАЦИЯ docker-compose.yml
# ==========================================
echo "📝 Создаем docker-compose.yml..."
cat <<DC > docker-compose.yml
services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: yt_backend
    restart: unless-stopped
    ports:
      - "127.0.0.1:8000:8000"

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: yt_frontend
    restart: unless-stopped
    environment:
      - HOST=0.0.0.0
      - PORT=3000
      - NUXT_PUBLIC_API_BASE=/api
    depends_on:
      - backend
    ports:
      - "127.0.0.1:3000:3000"

  nginx:
    image: nginx:alpine
    container_name: yt_nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - certs_data:/etc/letsencrypt
      - certbot_www:/var/www/certbot
    depends_on:
      - frontend
      - backend

  certbot:
    image: certbot/certbot:latest
    container_name: yt_certbot
    volumes:
      - certs_data:/etc/letsencrypt
      - certbot_www:/var/www/certbot

volumes:
  certs_data:
  certbot_www:
DC

# ==========================================
# 3. ВЫПУСК ВРЕМЕННОГО СЕРТИФИКАТА ДЛЯ СТАРТА NGINX
# ==========================================
echo "🔑 Выпускаем временный сертификат..."
docker compose down -v

path="/etc/letsencrypt/live/$DOMAIN"
docker compose run --rm --entrypoint \
  "sh -c 'mkdir -p $path && \
  openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -keyout \"$path/privkey.pem\" \
    -out \"$path/fullchain.pem\" \
    -subj \"/CN=localhost\"'" certbot

# ==========================================
# 4. ЗАПУСК NGINX И ПОЛУЧЕНИЕ НАСТОЯЩЕГО SSL
# ==========================================
echo "🌐 Запускаем контейнеры..."
docker compose up -d nginx backend frontend

echo "⏳ Ждем 5 секунд инициализации Nginx..."
sleep 5

echo "🧹 Удаляем временный сертификат..."
docker compose run --rm --entrypoint \
  "rm -Rf /etc/letsencrypt/live/$DOMAIN && \
  rm -Rf /etc/letsencrypt/archive/$DOMAIN && \
  rm -Rf /etc/letsencrypt/renewal/$DOMAIN.conf" certbot

echo "🔒 Запрашиваем реальный SSL-сертификат..."
docker compose run --rm --entrypoint \
  "certbot certonly --webroot -w /var/www/certbot \
    --register-unsafely-without-email \
    -d $DOMAIN \
    --rsa-key-size 4096 \
    --agree-tos \
    --force-renewal \
    --non-interactive" certbot

# ==========================================
# 5. ПЕРЕЗАПУСК NGINX ДЛЯ ПРИМЕНЕНИЯ SSL
# ==========================================
echo "🔄 Перезапускаем Nginx..."
docker compose restart nginx

echo "--------------------------------------------------------"
echo "🎉 ВСЁ ГОТОВО!"
echo "Твой сайт доступен по адресу: https://$DOMAIN"
echo "API бэкенда доступно по адресу: https://$DOMAIN/api/"
echo "--------------------------------------------------------"
