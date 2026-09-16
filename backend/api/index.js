// Punto de entrada para Vercel (serverless).
// En local seguimos usando server.js; Vercel en cambio llama a esta funcion en cada peticion.
const connectDB = require('../src/config/db');
const app = require('../src/app');

// Vercel reutiliza el mismo proceso entre peticiones seguidas ("caliente"),
// asi que guardamos la conexion para no conectarnos a Mongo una y otra vez.
let connection;

module.exports = async (req, res) => {
  try {
    connection ??= connectDB();
    await connection;
  } catch (err) {
    connection = undefined; // si fallo, la proxima peticion vuelve a intentar
    console.error('No se pudo conectar a MongoDB:', err.message);
    return res.status(503).json({ success: false, message: 'Base de datos no disponible' });
  }
  return app(req, res);
};
