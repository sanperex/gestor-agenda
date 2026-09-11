// Formato unico de respuesta exitosa: { success, message, data }.
// El Aprendiz B debe usar esta misma funcion en sus controladores.
function sendSuccess(res, statusCode, data, message) {
  res.status(statusCode).json({ success: true, message, data });
}

module.exports = { sendSuccess };
