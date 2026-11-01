require('dotenv').config();

const app = require('./app');
const connectDB = require('./config/database');
const { startReminderJob } = require('./jobs/reminderJob');

const PORT = process.env.PORT || 3000;

(async () => {
  if (!process.env.JWT_SECRET) {
    console.error('Thiếu JWT_SECRET trong file .env');
    process.exit(1);
  }
  await connectDB();
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`API đang chạy tại http://localhost:${PORT}/api`);
  });
  startReminderJob();
})();
