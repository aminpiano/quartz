# Stage 1 — build static site
FROM node:24-alpine AS builder
WORKDIR /app

# git: created-modified-date plugin reads git timestamps when frontmatter is missing
RUN apk add --no-cache git

# Cache-friendly: lockfile first, then full source
COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Install community plugins from lockfile, then build → public/
RUN npx quartz plugin install && npx quartz build

# Stage 2 — serve static
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/public /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://localhost/ || exit 1
