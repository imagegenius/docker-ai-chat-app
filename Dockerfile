FROM ghcr.io/imagegenius/baseimage-alpine:3.17

# set version label
ARG BUILD_DATE
ARG VERSION
ARG APP_VERSION
LABEL build_version="ImageGenius Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydazz"

# environment settings
ENV DATABASE_URL="file:/config/db.sqlite"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    git \
    npm && \  
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    yarn && \
  echo "**** install ai-chat-app ****" && \
  if [ -z ${APP_VERSION+x} ]; then \
    APP_VERSION=$(curl -sL "https://api.github.com/repos/bitswired/fuseai/commits?ref=main" | jq -r '.[0].sha' | cut -c1-8); \
  fi && \
  git clone https://github.com/bitswired/fuseai.git /app/ai-chat-app && \
  cd /app/ai-chat-app && \
  git checkout ${APP_VERSION} && \
  echo "**** build server ****" && \
  yarn && \
  yarn build && \
  npm prune --omit=dev --omit=optional && \
  npm cache clean --force && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    /root/.npm \
    /root/.cache \
    /usr/local/share/.cache

# environment settings
ENV NODE_ENV="production"

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 3000
VOLUME /config
