// Lee y valida las variables de entorno UNA sola vez.
// Si falta una obligatoria, el servidor se detiene con un mensaje claro.
const required = ['MONGODB_URI', 'JWT_SECRET'];

for (const name of required) {
  if (!process.env[name]) {
    console.error(`Falta la variable de entorno ${name}. Revisa backend/.env (guia: .env.example).`);
    process.exit(1);
  }
}

// CORS_ORIGIN puede ser "*" o una lista separada por comas.
const corsOrigin = process.env.CORS_ORIGIN || '*';

module.exports = {
  port: Number(process.env.PORT) || 3000,
  mongodbUri: process.env.MONGODB_URI,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  corsOrigin: corsOrigin === '*' ? '*' : corsOrigin.split(',').map((o) => o.trim()),
  // true = la respuesta de forgot-password incluye el código (solo para demo academica).
  resetCodeDemo: process.env.RESET_CODE_DEMO === 'true',
};
