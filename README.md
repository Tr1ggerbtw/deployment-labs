# Лабораторна робота 1
## Тема: Розгортання Web-сервісу з автоматизацією

**Працював над лабораторной роботою:** 
* **ІМ-41 Легеза Данііл Павлович**

## Варіант індивідуальних завдань
N - 11 \
V<sub>2</sub> = (N % 2) + 1 = 2 \
V<sub>3</sub> = (N % 3) + 1 = 3 \
V<sub>5</sub> = (N % 5) + 1 = 2 

## Документацію по розробленому веб-застосунку

Simple Inventory — сервіс обліку обладнання

Об’єкт інвентарю містить наступні поля
- id
- name
- quantity
- created_at

API сервісу складається з 3 ендпоінтів
- `GET /items` — вивести список усіх предметів в інвентарі (id,name)
- `POST /items` (name, quantity) — створити новий запис у системі обліку
- `GET /items/<id>` — вивести детальну інформацію по запису в інвентарі (id,
name, quantity, created_at)

Системні ендпоінти
* `GET /` — повертає HTML-сторінку зі списком усіх ендпоінтів.
* `GET /health/alive` — завжди повертає `HTTP 200 OK`.
* `GET /health/ready` — перевіряє підключення до бази даних. Повертає `HTTP 200 OK`, якщо підключення успішне, інакше `HTTP 500`.

## Порт застосунку та конфігурація

Конфігураційний файл за шляхом /etc/mywebapp/config.yaml

**Порт застосунку: 5200** \
**База даних: PostgreSQL**

## Реалізація веб-застосунку

* **Мова програмування:** Python 3
* **Фреймворк:** Flask

# Налаштування середовища

+ Клонування репозиторію
```bash
git clone https://github.com/Tr1ggerbtw/deployment-labs.git
```

+ Перехід у директорію проєкту
```bash
cd deployment-labs
```

### Запуск PostgreSQL
```bash
docker run -d --name postgres -e POSTGRES_PASSWORD=password123 -e POSTGRES_DB=inventory -p 5432:5432 postgres
```
### Створення та активація віртуального середовища
```bash
python3 -m venv venv # або просто python
source venv/bin/activate
pip install -r requirements.txt
```
### Запуск міграції і застосунку
```bash
python migrate.py
python run.py
```

# Документація по розгортанню

+ Образ для віртуальної машини: [image](https://ubuntu.com/download/server)

+ Клонування репозиторію
```bash
git clone https://github.com/Tr1ggerbtw/deployment-labs.git
```

+ Перехід у директорію проєкту
```bash
cd deployment-labs
```

+ Запуск скрипта розгортання
```bash
sudo bash deploy/setup.sh
```

# Тестування

### 1. Nginx & API Endpoints 

+ Тест кореневого ендпоінту (має повернути HTML-сторінку)
```bash
curl -i -H "Accept: text/html" http://localhost/
```

+ Тест безпеки Nginx: внутрішні перевірки стану мають бути заблоковані ззовні (403 Forbidden)
```bash
curl -i http://localhost/health/alive
```

+ Тест бізнес-логіки GET із заголовком Accept: application/json
```bash
curl -i -H "Accept: application/json" http://localhost/items
```

+ Тест бізнес-логіки GET із заголовком Accept: text/html
```bash
curl -i -H "Accept: text/html" http://localhost/items
```

+ Тест бізнес-логіки POST
```bash
curl -i -X POST -H "Content-Type: application/json" -d '{"name":"Test Item", "quantity":5}' http://localhost/items
```

### Користувачі та права доступу
+ 'teacher' user (Пароль за замовчування: '12345678')
```bash
su - teacher
sudo ls /root 
exit
```

+ 'operator' user (Пароль за замовчування: '12345678')
```bash
su - operator
sudo systemctl restart mywebapp.service
sudo ls /root
exit
```

+ Підтвердження що користувач за замовчення заблокований
```bash
sudo passwd -S ubuntu
```

# Результати автоматизації
+ Перевірка того, що веб-застосунок (Python/Gunicorn) працює
```
sudo systemctl status mywebapp.service
```

+ Перевірка того, що скрипт створив файл із номером варіанту
```bash
sudo cat /home/student/gradebook
```
