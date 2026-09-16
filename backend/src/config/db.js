const mongoose = require('mongoose');
const { mongodbUri } = require('./env');

async function connectDB() {
  // maxPoolSize bajo: en Vercel puede haber muchas instancias pequenas a la vez.
  await mongoose.connect(mongodbUri, { maxPoolSize: 5 });
  console.log(`MongoDB conectado (base: ${mongoose.connection.name})`);
}

module.exports = connectDB;
