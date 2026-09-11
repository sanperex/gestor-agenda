const ApiError = require('../utils/ApiError');

// Cualquier ruta que no exista.
function notFound(req, _res, next) {
  next(new ApiError(404, `Ruta no encontrada: ${req.method} ${req.originalUrl}`));
}

// Punto unico donde se convierten los errores en respuestas JSON: { success: false, message, errors? }.
function errorHandler(err, _req, res, _next) {
  let status = err.statusCode || 500;
  let message = err.message;
  let errors = err instanceof ApiError ? err.errors : undefined;

  if (err.type === 'entity.parse.failed') {
    status = 400;
    message = 'El cuerpo de la petición no es un JSON válido';
  } else if (err.code === 11000) {
    // Indice unico de MongoDB (ej. dos usuarios con el mismo correo al mismo tiempo).
    status = 409;
    message = 'El correo ya está registrado';
  } else if (err.name === 'ValidationError') {
    status = 400;
    errors = Object.values(err.errors).map((e) => e.message);
    message = errors[0];
  } else if (status === 500) {
    console.error(err); // el detalle se queda en el servidor, no se envia al cliente
    message = 'Error interno del servidor';
  }

  res.status(status).json({ success: false, message, ...(errors && { errors }) });
}

module.exports = { notFound, errorHandler };
