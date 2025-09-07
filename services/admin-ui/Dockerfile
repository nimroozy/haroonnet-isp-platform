FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json ./
RUN npm install

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build the application
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Create directories
RUN mkdir -p ./public .next

# Set permissions  
RUN chown nextjs:nodejs .next

# Copy built application (with error handling)
COPY --from=builder /app/public ./public 2>/dev/null || mkdir -p ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./ 2>/dev/null || echo "No standalone build found"
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static 2>/dev/null || echo "No static build found"

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
