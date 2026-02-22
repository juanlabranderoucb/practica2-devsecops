# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install && npm prune --production && find node_modules -name 'package.json' -delete

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copy only node_modules from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy only source code (not package files)
COPY src ./src

EXPOSE 3001
CMD ["node", "src/server.js"]