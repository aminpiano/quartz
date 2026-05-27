# Stage 1 — build static site
# slim (Debian) over alpine: Quartz CLI uses `#!/usr/bin/env -S node` shebang which BusyBox env doesn't support
FROM node:24-slim AS builder
WORKDIR /app

# git: created-modified-date plugin reads git timestamps when frontmatter is missing
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*

# Cache-friendly: lockfile first, then full source
COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Install community plugins from lockfile, then build → public/
RUN npx quartz plugin install && npx quartz build

# Stage 2 — serve static
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/public /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1
