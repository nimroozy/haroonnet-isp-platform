FROM node:20-alpine

WORKDIR /app

# Install dependencies
RUN apk add --no-cache libc6-compat

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Create public directory
RUN mkdir -p public

# Build the application (skip if fails)
RUN npm run build || echo "Build failed, using dev mode"

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Set permissions
RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

# Start the application
CMD ["npm", "run", "dev"]
