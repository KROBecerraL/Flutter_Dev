const express = require('express');
const app = express();
const jwt = require('jsonwebtoken');
const mysql = require('mysql2');
const fs = require('fs');
const crypto = require('crypto');
const admin = require('firebase-admin');
const morgan = require('morgan');
var serviceAccount = require('./messaging-app-d70e0-firebase-adminsdk-dvj2s-bdd12bb3c4.json');

//https://firebase.google.com/docs/reference/admin/node/firebase-admin.messaging?hl=es-419
//https://www.techotopia.com/index.php/Sending_Firebase_Cloud_Messages_from_a_Node.js_Server

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

app.use(morgan('dev'));
app.use(express.json());

app.get('/', (req, res) => {
    res.send('Server is up and running');
});


var con = mysql.createConnection({
    host: "localhost",
    user: "carolina",
    password: "Littledeerluhan3",
    database: "parcial_bd"
});

con.connect(function (err) {
    if (err) throw err;
    console.log("Connected!");
});

let users = [];

function getUsersQuery() {
    con.query("SELECT * FROM users", function (err, result, fields) {
        if (err) throw err;
        console.log(result);

        // assign the result to the users array
        users = result;
    });
}

getUsersQuery();

console.log(users);

const secretKey = 'secret@456()<>xo!*tyoiortoygkjdf*';

app.post('/register', (req, res) => {
    const { email, password, image, name, phone, job } = req.body;

    // Check if email already exists
    const userExists = users.some((user) => user.email === email);
    if (userExists) {
        return res.status(409).send('Email already exists');
    }

    // Hash the password using SHA-256
    const hashedPassword = crypto
        .createHash('sha256')
        .update(password)
        .digest('hex');

    // Print hashed password to check
    console.log('hashed password ' + hashedPassword);

    // Save the new user to the database
    const newUser = {
        email: email,
        password: hashedPassword,
        image: image,
        name: name,
        phone: phone,
        job: job
    };

    con.query('INSERT INTO users SET ?', newUser, function (err, result) {
        if (err) {
            console.error(err);
            return res.status(500).send('Error saving user to database');
        }

        console.log('User saved to database');

        getUsersQuery();

        //implicit login

        req.user = { name: name, email: email };

        const token = jwt.sign({ name: name, email: email }, secretKey, { expiresIn: '12h' });

        res.status(201).send({ token });
    });
});

app.post('/login', (req, res) => {
    const { email, password } = req.body;

    console.log("email: " + email);
    console.log("password: " + password);

    // Hash the password using SHA-256
    const hashedPassword = crypto
        .createHash('sha256')
        .update(password)
        .digest('hex');

    console.log("hashed password: " + hashedPassword);

    const user = users.find((u) => u.email === email && u.password === hashedPassword);

    console.log(users);

    if (!user) {
        return res.status(401).send('Invalid credentials!!!');
    }

    // Set email and password properties of req.user object
    req.user = { name: user.name, email: user.email };

    console.log("user name: " + user.name);
    console.log("email: " + user.email);

    const token = jwt.sign({ name: user.name, email: user.email }, secretKey, { expiresIn: '12h' });

    res.send({ token });
});

app.post('/fcm-token', (req, res) => {
    const { email, fToken } = req.body;

    // Check if the token already exists in the 'tokens' table
    con.query('SELECT * FROM tokens WHERE token = ?', fToken, function (err, result) {
        if (err) {
            console.error(err);
            return res.status(500).send('Error checking token in the database');
        }

        if (result.length > 0) {
            // Token already exists in the table
            return res.status(409).send('Token already exists, no need to add device again');
        }

        // Token does not exist, insert it into the 'tokens' table
        const newToken = { user_email: email, token: fToken }; // Updated column names

        con.query('INSERT INTO tokens SET ?', newToken, function (err, result) {
            if (err) {
                console.error(err);
                return res.status(500).send('Error saving token to database');
            }

            console.log('Token saved to database');
            res.status(201).send('Token registered successfully');
        });
    });
});


app.use((req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
        return res.status(401).send('Authorization header not found');
    }

    const token = authHeader.split(' ')[1];
    console.log(token);

    try {
        const decodedToken = jwt.verify(token, secretKey);

        req.user = { name: decodedToken.name, email: decodedToken.email };

        next();
    } catch (err) {
        return res.status(401).send('Invalid or expired token');
    }
});

app.get('/users/:email', (req, res) => {
    const userEmail = req.params.email;

    con.query('SELECT * FROM users WHERE email <> ?', userEmail, function (err, result) {
        if (err) {
            console.error(err);
            return res.status(500).send('Error retrieving users from the database');
        }

        console.log(result);
        res.json(result);
    });
});

app.post('/sendMsg', (req, res) => {
    const { title, body, sender_email, recipient_email } = req.body;

    // Check if sender and recipient emails exist in the users table
    con.query('SELECT * FROM users WHERE email IN (?, ?)', [sender_email, recipient_email], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Error checking user emails');
        }

        if (result.length !== 2) {
            return res.status(404).send('One or more user emails not found');
        }

        // Save the new message to the messages table
        const newMessage = {
            title: title,
            body: body,
            sender_email: sender_email,
            recipient_email: recipient_email
        };

        con.query('INSERT INTO messages SET ?', newMessage, (err, result) => {
            if (err) {
                console.error(err);
                return res.status(500).send('Error saving message to database');
            }

            console.log('Message saved to database under ID ' + result.insertId);

            // Retrieve the message_id of the newly created message
            const message_id = result.insertId;

            // Retrieve the tokens of the recipient_email from the tokens table
            con.query('SELECT token FROM tokens WHERE user_email = ?', recipient_email, (err, result) => {
                if (err) {
                    console.error(err);
                    return res.status(500).send('Error retrieving tokens from database');
                }

                console.log("Retrieved tokens from DB successfully");

                const token_ids = result.map((row) => row.token);

                // Create an array of arrays to be inserted into the message_tokens table
                const messageTokens = token_ids.map((token_id) => [message_id, token_id]);

                // Insert the message-token mappings into the message_tokens table
                con.query('INSERT INTO message_tokens (message_id, token) VALUES ?', [messageTokens], async (err, result) => {
                    if (err) {
                        console.error(err);
                        return res.status(500).send('Error saving message tokens to database');
                    }

                    console.log('Message tokens saved to database');
                    res.status(201).send('Message created successfully');
                    // Retrieve the FCM tokens for the recipient_email
                    const fcmTokens = token_ids;

                    // Construct the notification payload
                    const payload = {
                        notification: {
                            title: title,
                            body: body,
                            click_action: 'FLUTTER_NOTIFICATION_CLICK'
                        },
                        data: {
                            message_id: message_id.toString()
                        }
                    };

                    // Send push notifications using the Firebase Admin SDK
                    try {
                        const response = await admin.messaging().sendToDevice(fcmTokens, payload, {
                            contentAvailable: true,
                            priority: 'high'
                        });

                        console.log('Push notification sent:', response);
                    } catch (error) {
                        console.error('Error sending push notification:', error);
                    }
                });
            });
        });
    });
});


app.get('/protected', (req, res) => {
    const userEmail = req.user.email;
    res.send(`This is a protected route, user: ${userEmail}`);
});

app.get('/logout', (req, res) => {
    req.user = null;
    res.send('Logged out successfully');
});


app.listen(8080, () => console.log('Server started on port 8080'));
console.log('Server is listening...');