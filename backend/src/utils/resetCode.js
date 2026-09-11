const crypto = require('crypto');

const RESET_CODE_MINUTES = 15;
const MAX_RESET_ATTEMPTS = 5;

// El código se guarda con hash: si alguien ve la base de datos, no ve el código.
const hashCode = (code) => crypto.createHash('sha256').update(code).digest('hex');

function generateResetCode() {
  const code = crypto.randomInt(0, 1_000_000).toString().padStart(6, '0');
  return {
    code,
    hash: hashCode(code),
    expires: new Date(Date.now() + RESET_CODE_MINUTES * 60 * 1000),
  };
}

// Por ahora el "envio" es un mensaje en la consola (se ve en los logs de Railway).
// Para correo real, solo se cambia esta funcion (ej. API de Resend).
async function sendResetCode(email, code) {
  console.log(`[RECUPERACIÓN] Código para ${email}: ${code} (vence en ${RESET_CODE_MINUTES} min)`);
}

module.exports = { hashCode, generateResetCode, sendResetCode, MAX_RESET_ATTEMPTS };
