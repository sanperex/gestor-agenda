const ApiError = require('../utils/ApiError');
const { verifyToken } = require('../utils/token');

// Protege rutas: exige "Authorization: Bearer <token>" y deja el id del usuario en req.userId.
// Aprendiz B: usar en sus rutas -> router.use(requireAuth) y filtrar con { userId: req.userId }.
function requireAuth(req, _res, next) {
  const [type, token] = (req.headers.authorization || '').split(' ');
  if (type !== 'Bearer' || !token) {
    throw new ApiError(401, 'No autenticado: falta el token');
  }

  let payload;
  try {
    payload = verifyToken(token);
  } catch {
    throw new ApiError(401, 'Token inválido o vencido');
  }

  req.userId = payload.sub;
  next();
}

module.exports = requireAuth;
