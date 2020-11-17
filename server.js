'use strict';

const express = require('express');
var path = require('path');


var fs = require('fs');
const index_path = path.join(__dirname + '/index.html');
fs.readFile(index_path, 'utf8', function (err, data) {
    if (err) {
        return console.log(err);
    }
    var result = data.replace(/APP_NAME/g, process.env.APP_NAME);

    fs.writeFile(index_path, result, 'utf8', function (err) {
        if (err) return console.log(err);
    });
});

// Constants
const PORT = 8080;
const HOST = '0.0.0.0';

// App
const app = express();
app.get('/', (req, res) => {
    res.sendFile(index_path);
});

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
