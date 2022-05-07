ARG BASE_IMAGE="node"
ARG BASE_IMAGE_TAG="16.15.0-buster-slim"

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG}
RUN apt-get update && apt-get install -y wget

# Install dependencies - cache it
WORKDIR /usr/src/server
COPY server/package*.json server/yarn.lock ./
RUN yarn install

# Copy server source code
COPY server ./

# Copy app source code
WORKDIR /usr/src/app
COPY app ./

# Runtime workdir
WORKDIR /usr/src/

# Run as a non-root user
RUN addgroup appgroup && \
    useradd appuser --gid appgroup --home-dir /usr/src && \
    chown -R appuser:appgroup /usr/src
USER appuser

# For documentation only
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 CMD  wget --spider -S http://localhost:8080/healthy || exit 1

LABEL maintainer="Meir Gabay"

CMD [ "node", "server/server.js" ]
