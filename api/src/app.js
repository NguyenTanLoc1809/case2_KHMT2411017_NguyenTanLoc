const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const { notFound, errorHandler } = require('./middleware/errorMiddleware');

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));
if (process.env.NODE_ENV !== 'test') app.use(morgan('dev'));

app.get('/api/health', (req, res) => res.json({ success: true, message: 'OK' }));

// Mỗi dòng gắn với một nhóm chức năng (A, B, C, D, E) để commit theo từng nhánh
app.use('/api/auth', require('./routes/authRoutes')); // [A]
app.use('/api/users', require('./routes/userRoutes')); // [A] + dùng cho [C]
app.use('/api/tasks', require('./routes/taskRoutes')); // [B] (+ assignees/shares [C], email-logs [D])
app.use('/api/notifications', require('./routes/notificationRoutes')); // [D]
app.use('/api/email-logs', require('./routes/emailLogRoutes')); // [D]
app.use('/api/statistics', require('./routes/statisticsRoutes')); // [E]

app.use(notFound);
app.use(errorHandler);

module.exports = app;
