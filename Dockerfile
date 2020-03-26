#
# ---- Base Node ----
FROM node:10-alpine AS base
RUN apk add --no-cache tini
# set working directory
WORKDIR /root/chat
# Set tini as entrypoint
ENTRYPOINT ["/sbin/tini", "--"]
# copy project file
COPY package.json .

RUN npm set progress=false && \
    npm config set depth 0 && \
    npm install --only=production

#
# ---- Dependencies ----
FROM base AS dependencies
# install node packages
RUN npm install
# copy app sources
COPY . .

RUN npm run build

#
# ---- Release ----
FROM base AS release
WORKDIR /root/chat

COPY --from=dependencies /root/chat/.nuxt ./.nuxt
# expose port and define CMD
EXPOSE 1000
CMD npm run start
