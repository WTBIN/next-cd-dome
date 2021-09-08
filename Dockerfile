# 仅在需要时安装依赖项
FROM node:alpine AS deps
# 查看 https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine 了解为什么可能需要 libc6-compat。
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# 仅在需要时重新构建源代码
FROM node:alpine AS builder
WORKDIR /app
COPY . .
COPY --from=deps /app/node_modules ./node_modules
RUN yarn build && yarn install --production --ignore-scripts --prefer-offline

# 生产镜像，复制所有文件，然后运行
FROM node:alpine AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# 如果您不使用默认配置，则只需复制 next.config.js
# COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

USER nextjs

EXPOSE 3000

# Next.js 收集关于一般用途的完全匿名的遥测数据。
# Learn more here: https://nextjs.org/telemetry
# 如果要禁用遥测，请取消注释以下行。
# ENV NEXT_TELEMETRY_DISABLED 1

CMD ["yarn", "start"]