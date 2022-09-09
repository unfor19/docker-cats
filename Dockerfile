ARG BASE_IMAGE="node"
ARG BASE_IMAGE_TAG="18.9.0-slim"

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG} as base
RUN apt-get update && apt-get install -y wget

FROM base as dev
RUN echo deb http://deb.debian.org/debian buster-backports main | tee /etc/apt/sources.list.d/buster-backports.list && \
    apt-get update && \
    apt-get install -y \
    zip unzip make bsdmainutils git bash-completion && \
    echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc
RUN wget -q -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x jq && \
    mv jq /usr/local/bin/jq

WORKDIR /code/
ENTRYPOINT [ "bash" ]
# docker run -v "$PWD":/code/ ...

FROM base as app
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

# Run as a non-root user - DOES NOT WORK
# Non-privileged user (not root) can't open a listening socket on ports below 1024.
# https://stackoverflow.com/a/60373143/5285732

# EXPOSE is for documentation only - does not do anything
# 8080 is the default port the server is listening on
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 CMD  wget --spider -S http://localhost:8080/healthy || exit 1

LABEL maintainer="Meir Gabay"

CMD [ "node", "server/server.js" ]
