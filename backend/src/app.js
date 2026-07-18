require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const usersRouter = require('./routes/users');
const tripsRouter = require('./routes/trips');
const paymentsRouter = require('./routes/payments');
const sectorsRouter = require('./routes/sectors');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

app.use('/api/v1/users', usersRouter);
app.use('/api/v1/auth', usersRouter);
app.use('/api/v1/profile', usersRouter);
app.use('/api/v1/trips', tripsRouter);
app.use('/api/v1/payments', paymentsRouter);
app.use('/api/v1/sectors', sectorsRouter);

app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(PORT, () => {
    console.log(`Rabt Backend running on port ${PORT}`);
});
