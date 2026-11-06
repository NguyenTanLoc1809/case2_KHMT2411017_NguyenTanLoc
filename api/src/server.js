require('dotenv').config();
const app = require('./app');
const connectDB = require('./config/database');

const PORT = process.env.PORT || 3000;

connectDB()
  .then(() => {
    app.listen(PORT, () => console.log(`API dang chay tai http://localhost:${PORT}/api`));
  })
  .catch((err) => {
    console.error('Khong the ket noi MongoDB:', err.message);
    process.exit(1);
  });
