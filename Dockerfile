FROM ghcr.io/imagegenius/baseimage-alpine:3.18

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
    git && \  
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    npm && \
  echo "**** install fuseai ****" && \
  if [ -z ${APP_VERSION+x} ]; then \
    APP_VERSION=$(curl -sL "https://api.github.com/repos/bitswired/fuseai/commits?ref=main" | jq -r '.[0].sha' | cut -c1-8); \
  fi && \
  git clone https://github.com/bitswired/fuseai.git /app/fuseai && \
  cd /app/fuseai && \
  git checkout ${APP_VERSION} && \
  echo "**** build server ****" && \
  sed -i \
    's/"next": "^13.2.1"/"next": "13.4.3"/; s/"next-auth": "^4.20.1"/"next-auth": "4.22.1"/' \
    package.json && \
  npm install && \
  npm ci && \
  npm run build && \
  npm prune --omit=dev --omit=optional && \
  npm cache clean --force && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    /root/.npm \
    /root/.cache

# environment settings
ENV NODE_ENV="production"

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 3000
VOLUME /config
