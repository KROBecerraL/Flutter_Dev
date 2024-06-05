const express = require('express');
const jwt = require('jsonwebtoken');
const mysql = require('mysql2');

const app = express();
app.use(express.json());

app.get('/', (req, res) => {
    res.send('Server is up and running');
});

var con = mysql.createConnection({
    host: "localhost",
    user: "carolina",
    password: "Littledeerluhan3",
    database: "mobile_bd"
});

con.connect(function (err) {
    if (err) throw err;
    console.log("Connected!");
});

let users = [];

function getUsersQuery() {
    con.query("SELECT * FROM Users", function (err, result, fields) {
        if (err) throw err;
        console.log(result);

        // assign the result to the users array
        users = result;
    });
}

getUsersQuery();

console.log(users);

const secretKey = 'secret@456()<>xo!*tyoiortoygkjdf*';

app.post('/login', (req, res) => {
    const { username, password } = req.body;

    const user = users.find(u => u.username === username && u.password === password);

    if (!user) {
        return res.status(401).send('Invalid credentials!!!');
    }

    // Set username and password properties of req.user object
    req.user = { username: user.username, password: user.password };

    const token = jwt.sign({ userId: user.id, username: user.username, password: user.password }, secretKey, { expiresIn: '2h' });

    res.send({ token });
});

app.post('/authtoken', (req, res) => {
    const { printToken } = req.body;

    console.log('req: ' + printToken);

    con.query(`SELECT id, username FROM Users WHERE token = '${printToken}'`, (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send({ success: false, message: 'Internal server error' });
        }

        if (result.length === 0) {
            console.log(`Token not found`);
            return res.status(404).send({ success: false, message: 'Token not found' });
        }

        const user = result[0];
        console.log(`Token found for user ${user.username}`);

        const token = jwt.sign({ userId: user.id, username: user.username}, secretKey, { expiresIn: '2h' });

        return res.send({ token });
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

        req.user = { userId: decodedToken.userId, username: decodedToken.username, password: decodedToken.password };

        next();
    } catch (err) {
        return res.status(401).send('Invalid or expired token');
    }
});

app.post('/confirmcreds', (req, res) => {
    const { username, password } = req.body;

    console.log(req.body);
    console.log(req.user);
    console.log(req.user.username);

    // Check if username and password match the ones stored in req.user object
    if (req.user && req.user.username === username && req.user.password === password) {
        const confirmed = true;

        const printToken = jwt.sign({ userId: req.user.id, username: req.user.username }, secretKey);

        con.query(`UPDATE Users SET token='${printToken}' WHERE username='${username}'`, (err, result) => {
            if (err) throw err;
            console.log(`Token updated for ${username}`);
            console.log(`New token: ${printToken}`)
        });

        return res.send({ printToken });
    } else {
        console.log("No match");
        return res.status(401).send('Invalid credentials!!!');
    }
});

app.post('/disableprint', (req, res) => {
    const { printToken } = req.body;

    console.log('req: ' + printToken);

    // Find which table value has that token and make the token null
    con.query(`UPDATE Users SET token = NULL WHERE token = '${printToken}'`, (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send({ success: false, message: 'Internal server error' });
        }
        console.log(`Token disabled for ${result.affectedRows} user(s)`);
        return res.send({ success: true, printToken: printToken });
    });
});

app.get('/protected', (req, res) => {
    const userId = req.user.userId;
    res.send(`This is a protected route, user ID: ${req.user.userId}`);
});

app.get('/logout', (req, res) => {
    req.user = null;
    res.send('Cookie deleted');
});

app.listen(8080, () => console.log('Server started on port 8080'));
console.log('Server is listening...');
