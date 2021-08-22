FROM node:12.19.1-alpine3.11

WORKDIR /usr/src/app
COPY . .
RUN npm install

EXPOSE 8080
CMD [ "node", "server.js" ]
