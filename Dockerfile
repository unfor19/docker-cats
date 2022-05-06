ARG NODE_VERSION="12.9.1"
ARG ALPINE_VERSION="3.11"


FROM node:${NODE_VERSION}-${ALPINE_VERSION}}
WORKDIR /usr/src/app

# Install dependencies - cache it
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# For documentation only
EXPOSE 8080

CMD [ "node", "server.js" ]
