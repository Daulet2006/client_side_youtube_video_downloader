# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /app

COPY package*.json ./
# Исключаем лишний кэш npm при установке
RUN npm ci --prefer-offline --no-audit && npm cache clean --force

COPY . .
RUN npm run build

# Stage 2: Production Run
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

# Копируем только результаты сборки и package.json
COPY --from=builder /app/.output ./.output

EXPOSE 3000
CMD ["node", ".output/server/index.mjs"]