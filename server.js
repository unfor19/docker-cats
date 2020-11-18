'use strict';

const express = require('express');
var path = require('path');
const logger = function (req, res, next) {
    console.log(`\nOriginal URL: ${req.originalUrl}\nBase URL: ${req.baseUrl}\nPath: ${req.path}\nRoute: ${JSON.stringify(req.route)}\nBody: ${req.body}\n`);
    next(); // Passing the request to the next handler in the stack.
}

var fs = require('fs');
const index_path = path.join(__dirname + '/index.html');

// Constants
const APP_NAME = process.env.APP_NAME;
const PORT = 8080;
const HOST = '0.0.0.0';

// App
const app = express();
fs.readFile(index_path, 'utf8', function (err, data) {
    if (err) {
        return console.log(err);
    }
    var result = data.replace(/APP_NAME/g, APP_NAME);

    fs.writeFile(index_path, result, 'utf8', function (err) {
        if (err) return console.log(err);
    });
});

app.use(logger);

app.get('/', (req, res) => {
    res.sendFile(index_path);
});

// app.get(`/${APP_NAME}`, (req, res) => {
//     res.sendFile(index_path);
// });


app.use('/images', express.static(path.join(__dirname, 'images')))
// app.use(`/${APP_NAME}/images`, express.static(path.join(__dirname, 'images')))
app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
