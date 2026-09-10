const { port } = require('./src/config/env');
const connectDB = require('./src/config/db');
const app = require('./src/app');

// Primero conecta a MongoDB y despues abre el puerto.
async function start() {
  try {
    await connectDB();
    app.listen(port, () => console.log(`API escuchando en http://localhost:${port}`));
  } catch (err) {
    console.error('No se pudo conectar a MongoDB:', err.message);
    process.exit(1);
  }
}

start();
