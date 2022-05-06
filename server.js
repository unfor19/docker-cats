'use strict';

// Requirements
const fs = require('fs');
const path = require('path');

const express = require('express');
const favicon = require('serve-favicon');
const { OAuth2Client } = require('google-auth-library');

// Constants
const index_path = path.join(__dirname + '/index.html');
const APP_NAME = process.env.APP_NAME;
const FROM_AUTHOR = process.env.FROM_AUTHOR ? process.env.FROM_AUTHOR : APP_NAME;
const PORT = process.env.PORT ? process.env.PORT : 8080;
const HOST = process.env.HOST ? process.env.HOST : '0.0.0.0';
const CLIENT_ID = process.env.CLIENT_ID ? process.env.CLIENT_ID : '';


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


async function verifyToken(token) {
    const client = new OAuth2Client(CLIENT_ID);
    async function verify() {
        const ticket = await client.verifyIdToken({
            idToken: token,
            audience: CLIENT_ID,  // Specify the CLIENT_ID of the app that accesses the backend
            // Or, if multiple clients access the backend:
            //[CLIENT_ID_1, CLIENT_ID_2, CLIENT_ID_3]
        });
        const payload = ticket.getPayload();
        // const userid = payload['sub'];
        // If request specified a G Suite domain:
        // const domain = payload['hd'];

        return payload
    }
    return verify().catch(error => {
        console.log(error);
        return false;
    });
}

// Endpoints
app.get('/', async (req, res) => {
    var fileStream = read_file();
    var requesting_user = null


    if (req.headers.hasOwnProperty('authorization') && CLIENT_ID != '') {
        const token = req.headers.authorization.split(" ")[1];
        var verifiedTokenResponse = await verifyToken(token);
        if (verifiedTokenResponse != false) {
            console.log(JSON.stringify(verifiedTokenResponse, null, 2));
            if (verifiedTokenResponse.hasOwnProperty('name')) {
                requesting_user = verifiedTokenResponse['name']
            }
        }
    }


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
