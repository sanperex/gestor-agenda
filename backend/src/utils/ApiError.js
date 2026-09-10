// Error con código HTTP. Se lanza con "throw" y lo atrapa error.middleware.js.
class ApiError extends Error {
  constructor(statusCode, message, errors) {
    super(message);
    this.statusCode = statusCode;
    this.errors = errors; // lista opcional de detalles (ej. campos invalidos)
  }
}

module.exports = ApiError;
