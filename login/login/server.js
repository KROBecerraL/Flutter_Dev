const express = require('express');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

app.get('/', (req, res) => {
    res.send('Server is up and running');
});

const users = [
    { id: 1, username: 'carolina@gmail.com', password: 'contraseña1' },
    { id: 2, username: 'ali@gmail.com', password: 'contraseña2' },
];

const secretKey = 'secret@456()<>xo!*tyoiortoygkjdf*';

app.post('/login', (req, res) => {
    const { username, password } = req.body;

    const user = users.find(u => u.username === username && u.password === password);

    if (!user) {
        return res.status(401).send('Invalid credentials!!!');
    }

    const token = jwt.sign({ userId: user.id }, secretKey, { expiresIn: '2h' });

    res.send({ token });
});

app.use((req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
        return res.status(401).send('Authorization header not found');
    }

    const token = authHeader.split(' ')[1];

    try {
        const decodedToken = jwt.verify(token, secretKey);

        req.user = { userId: decodedToken.userId };
        next();
    } catch (err) {
        return res.status(401).send('Invalid or expired token');
    }
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
