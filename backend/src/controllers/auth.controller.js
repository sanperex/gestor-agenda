const bcrypt = require('bcryptjs');
const User = require('../models/user.model');
const ApiError = require('../utils/ApiError');
const { sendSuccess } = require('../utils/response');
const { signToken } = require('../utils/token');
const { resetCodeDemo } = require('../config/env');
const { hashCode, generateResetCode, sendResetCode, MAX_RESET_ATTEMPTS } = require('../utils/resetCode');
const {
  validateRegister,
  validateLogin,
  validateForgotPassword,
  validateResetPassword,
} = require('../utils/validators');

const SALT_ROUNDS = 10;

// Express 5 atrapa solo los errores de funciones async: basta con "throw".

// POST /api/auth/register
async function register(req, res) {
  const { name, email, password } = validateRegister(req.body);

  if (await User.exists({ email })) {
    throw new ApiError(409, 'El correo ya está registrado');
  }

  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
  const user = await User.create({ name, email, password: passwordHash });

  sendSuccess(res, 201, { user, token: signToken(user.id) }, 'Usuario registrado');
}

// POST /api/auth/login
async function login(req, res) {
  const { email, password } = validateLogin(req.body);

  const user = await User.findOne({ email }).select('+password');
  const isValid = user && (await bcrypt.compare(password, user.password));

  // Mismo mensaje si el correo no existe o la contraseña esta mal: no revelamos que correos existen.
  if (!isValid) {
    throw new ApiError(401, 'Correo o contraseña incorrectos');
  }

  sendSuccess(res, 200, { user, token: signToken(user.id) }, 'Sesión iniciada');
}

// GET /api/auth/me  (requiere token)
async function me(req, res) {
  const user = await User.findById(req.userId);
  if (!user) {
    throw new ApiError(404, 'Usuario no encontrado');
  }
  sendSuccess(res, 200, { user }, 'Usuario actual');
}

// POST /api/auth/forgot-password
async function forgotPassword(req, res) {
  const { email } = validateForgotPassword(req.body);
  const user = await User.findOne({ email });
  const data = {};

  if (user) {
    const { code, hash, expires } = generateResetCode();
    user.resetCodeHash = hash;
    user.resetCodeExpires = expires;
    user.resetAttempts = 0;
    await user.save();
    await sendResetCode(user.email, code);
    if (resetCodeDemo) data.demoCode = code; // solo en modo demo
  }

  // Respuesta generica: igual exista o no el correo.
  sendSuccess(res, 200, data, 'Si el correo está registrado, se envió un código de recuperación');
}

// POST /api/auth/reset-password
async function resetPassword(req, res) {
  const { email, code, newPassword } = validateResetPassword(req.body);
  const user = await User.findOne({ email }).select('+resetCodeHash +resetCodeExpires +resetAttempts');
  const invalidCode = new ApiError(400, 'Código inválido o vencido');

  if (!user || !user.resetCodeHash || user.resetCodeExpires < new Date()) {
    throw invalidCode;
  }
  if (user.resetAttempts >= MAX_RESET_ATTEMPTS) {
    throw new ApiError(429, 'Demasiados intentos. Solicita un código nuevo');
  }
  if (hashCode(code) !== user.resetCodeHash) {
    user.resetAttempts += 1;
    await user.save();
    throw invalidCode;
  }

  user.password = await bcrypt.hash(newPassword, SALT_ROUNDS);
  user.resetCodeHash = undefined;
  user.resetCodeExpires = undefined;
  user.resetAttempts = 0;
  await user.save();

  sendSuccess(res, 200, {}, 'Contraseña actualizada. Ya puedes iniciar sesión');
}

module.exports = { register, login, me, forgotPassword, resetPassword };
