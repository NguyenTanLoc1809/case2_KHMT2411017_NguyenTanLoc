const mongoose = require('mongoose');

async function connectDB() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('Thieu bien moi truong MONGODB_URI');
  }
  await mongoose.connect(uri);
  console.log('Da ket noi MongoDB');
}

module.exports = connectDB;
