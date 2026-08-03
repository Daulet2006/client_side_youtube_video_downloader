# --- Stage 1: Build ---
FROM node:22-alpine AS builder

WORKDIR /app

# Копируем манифесты пакетов для эффективного кеширования
COPY package*.json ./

# Используем clean install для воспроизводимых сборок
RUN npm ci

# Копируем исходники и собираем проект
COPY . .
RUN npm run build

# --- Stage 2: Runner (Финальный легкий образ) ---
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Копируем из builder ТОЛЬКО результат сборки Nuxt
COPY --from=builder /app/.output ./.output

EXPOSE 3000

CMD ["node", ".output/server/index.mjs"]