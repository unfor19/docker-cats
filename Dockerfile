ARG BASE_IMAGE="node"
ARG BASE_IMAGE_TAG="16.15.0-buster-slim"

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG}

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

# For documentation only
EXPOSE 8080

CMD [ "node", "server/server.js" ]
