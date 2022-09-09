"use strict";

// Requirements
const fs = require("fs");
const http = require("http");
const path = require("path");

const express = require("express");
const favicon = require("serve-favicon");
var winston = require("winston"),
  expressWinston = require("express-winston");
const { OAuth2Client } = require("google-auth-library");

// Constants
const index_path = path.join(".", "app", "src", "index.html");
const APP_NAME = process.env.APP_NAME;
const FROM_AUTHOR = process.env.FROM_AUTHOR
  ? process.env.FROM_AUTHOR
  : APP_NAME;
const PORT = process.env.PORT ? process.env.PORT : 8080;
const HOST = process.env.HOST ? process.env.HOST : "0.0.0.0";
const CLIENT_ID = process.env.CLIENT_ID ? process.env.CLIENT_ID : "";
const SIGTERM_STOP_TIMEOUT_SECONDS = process.env.SIGTERM_STOP_TIMEOUT_SECONDS
  ? parseInt(process.env.SIGTERM_STOP_TIMEOUT_SECONDS)
  : 100; // Defaults to 100 seconds

// App
const app = express();

function read_file() {
  return fs.readFileSync(index_path, "utf8", function (err, data) {
    if (err) {
      return console.log(err);
    }
    return data;
  });
}

// Logging
const routeWhitelist = ["/"];

app.use(
  expressWinston.logger({
    transports: [new winston.transports.Console()],
    format: winston.format.combine(
      // winston.format.colorize(),
      winston.format.json()
    ),
    meta: true, // optional: control whether you want to log the meta data about the request (default to true)
    msg: "HTTP {{req.method}} {{req.url}}", // optional: customize the default logging message. E.g. "{{res.statusCode}} {{req.method}} {{res.responseTime}}ms {{req.url}}"
    expressFormat: true, // Use the default Express/morgan request formatting. Enabling this will override any msg if true. Will only output colors with colorize set to true
    colorize: false, // Color the text and status code, using the Express/morgan color palette (text: gray, status: default green, 3XX cyan, 4XX yellow, 5XX red).
    // ignoreRoute: function (req, res) {
    //   return false;
    // }, // optional: allows to skip some log messages based on request and/or response
    ignoreRoute: function (req, res) {
      return routeWhitelist.indexOf(req.path) === -1;
    },
  })
);

async function verifyToken(token) {
  const client = new OAuth2Client(CLIENT_ID);
  async function verify() {
    const ticket = await client.verifyIdToken({
      idToken: token,
      audience: CLIENT_ID, // Specify the CLIENT_ID of the app that accesses the backend
      // Or, if multiple clients access the backend:
      //[CLIENT_ID_1, CLIENT_ID_2, CLIENT_ID_3]
    });
    const payload = ticket.getPayload();
    // const userid = payload['sub'];
    // If request specified a G Suite domain:
    // const domain = payload['hd'];

    return payload;
  }
  return verify().catch((error) => {
    console.log(error);
    return false;
  });
}

// Endpoints
app.get("/", async (req, res) => {
  var fileStream = read_file();
  var requesting_user = null;

  if (req.headers.hasOwnProperty("authorization") && CLIENT_ID != "") {
    const token = req.headers.authorization.split(" ")[1];
    var verifiedTokenResponse = await verifyToken(token);
    if (verifiedTokenResponse != false) {
      console.log(JSON.stringify(verifiedTokenResponse, null, 2));
      if (verifiedTokenResponse.hasOwnProperty("name")) {
        requesting_user = verifiedTokenResponse["name"];
      }
    }
  }

  var to_user = requesting_user == null ? "" : requesting_user;
  var parsedStream = fileStream
    .replace(/APP_NAME/g, APP_NAME)
    .replace(/FROM_AUTHOR/g, FROM_AUTHOR)
    .replace(/TO_USER/g, to_user);
  res.set("Content-Type", "text/html");
  res.send(parsedStream);
});

app.get("/healthy", async (req, res) => {
  res.status(200).send({
    status: 200,
    healthy: "true",
  });
});

app.use("/images", express.static(path.join(".", "app", "images")));
app.use(favicon(path.join(".", "app", "src", "favicon.ico")));

// Main
app.listen(PORT, HOST);
const server = http.createServer(app);

// Graceful termination
process.on("SIGTERM", () => {
  console.log(
    `SIGTERM signal received: closing HTTP server in ${SIGTERM_STOP_TIMEOUT_SECONDS} seconds`
  );
  setTimeout(() => {
    server.close(() => {
      console.log("HTTP server closed, closing process");
      process.exit(143); // SIGTERM
    });
  }, SIGTERM_STOP_TIMEOUT_SECONDS * 1000);
});

// Keyboard interrupt - CTRL+C
process.on("SIGINT", () => {
  console.log(`SIGINT signal received: closing HTTP server`);
  server.close(() => {
    console.log("HTTP server closed, closing process");
    process.exit(130); // SIGINT
  });
});

console.log(`Running on http://${HOST}:${PORT}`);
