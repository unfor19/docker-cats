ARG BASE_IMAGE="node"
ARG BASE_IMAGE_TAG="16.15.0-buster-slim"

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG}
WORKDIR /usr/src/app

# Install dependencies - cache it
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# For documentation only
EXPOSE 8080

CMD [ "node", "server.js" ]
