FROM python:3.12-slim AS runner

# Предотвращаем запись .pyc файлов и включение буферизации логов
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 1. Сначала копируем только requirements для кеширования слоя с библиотеками
COPY requirements.txt .

# 2. Устанавливаем библиотеки без сохранения кэша wheel/tar
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 3. Копируем исходники приложения (изменения в коде больше не пересобирают pip install)
COPY app ./app

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]