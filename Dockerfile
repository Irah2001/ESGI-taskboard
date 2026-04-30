# ------------------------------------
# Étape 1 : Builder (Image de construction)
# ------------------------------------
FROM node:20.12.2-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci

COPY . .

# ------------------------------------
# Étape 2 : Runner (Image finale de production)
# ------------------------------------
FROM node:20.12.2-alpine AS runner

ENV NODE_ENV=production
WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci --omit=dev && npm cache clean --force

COPY --chown=node:node --from=builder /app/src ./src
COPY --chown=node:node --from=builder /app/db ./db

USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "src/server.js"]
