'use strict';

// Requirements
const fs = require('fs');
const path = require('path');

const express = require('express');
const favicon = require('serve-favicon');


// Constants
const index_path = path.join(__dirname + '/index.html');
const APP_NAME = process.env.APP_NAME;
const FROM_AUTHOR = process.env.FROM_AUTHOR ? process.env.FROM_AUTHOR : APP_NAME;
const PORT = process.env.PORT ? process.env.PORT : 8080;
const HOST = process.env.HOST ? process.env.HOST : '0.0.0.0';


// App
const app = express();

function read_file() {
    return fs.readFileSync(index_path, 'utf8', function (err, data) {
        if (err) {
            return console.log(err);
        }
        return data;
    });
}


// Logging
const logger = function (req, res, next) {
    console.log(`\nOriginal URL: ${req.originalUrl}\nBase URL: ${req.baseUrl}\nPath: ${req.path}\nRoute: ${JSON.stringify(req.route)}\nBody: ${req.body}`);
    console.log(`Request Headers:\n${JSON.stringify(req.headers, null, 2)}`);
    next(); // Passing the request to the next handler in the stack.
}
app.use(logger);


// Endpoints
app.get('/', (req, res) => {
    var fileStream = read_file();
    var requesting_user = null
    var to_user = requesting_user == null ? "" : requesting_user;
    var parsedStream = fileStream.replace(/APP_NAME/g, APP_NAME).replace(/FROM_AUTHOR/g, FROM_AUTHOR).replace(/TO_USER/g, to_user);
    res.set('Content-Type', 'text/html');
    res.send(parsedStream);
});


// Main
app.use(favicon(path.join(__dirname, 'favicon.ico')));
app.use('/images', express.static(path.join(__dirname, 'images')));
app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
