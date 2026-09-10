const mongoose = require('mongoose');
const { mongodbUri } = require('./env');

async function connectDB() {
  await mongoose.connect(mongodbUri);
  console.log(`MongoDB conectado (base: ${mongoose.connection.name})`);
}

module.exports = connectDB;
