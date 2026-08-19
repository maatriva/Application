FROM node:20-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./
COPY tsconfig.json ./
COPY prisma.config.ts ./
COPY prisma/ ./prisma/

RUN npm ci

RUN npx prisma generate

COPY src/ ./src/

RUN npm run build

FROM node:20-alpine

WORKDIR /usr/app

COPY package*.json ./
COPY prisma.config.ts ./
COPY prisma/ ./prisma/

RUN npm ci --only=production

RUN npx prisma generate

COPY --from=builder /usr/src/app/dist ./dist

RUN chown -R node:node /usr/app

USER node

EXPOSE 3000

CMD ["node", "dist/src/app.js"]

