const mongoose = require('mongoose');

module.exports = async function connectDB() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('Thiếu MONGODB_URI trong file .env');
    process.exit(1);
  }
  try {
    await mongoose.connect(uri);
    console.log('Đã kết nối MongoDB');
  } catch (err) {
    console.error('Không kết nối được MongoDB:', err.message);
    process.exit(1);
  }
};
