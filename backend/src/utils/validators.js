const ApiError = require('./ApiError');

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MIN_PASSWORD = 6;

// Devuelve el texto sin espacios a los lados, o '' si no es texto.
const text = (value) => (typeof value === 'string' ? value.trim() : '');

function checkEmail(email, errors) {
  if (!email) errors.push('El correo es obligatorio');
  else if (!EMAIL_REGEX.test(email)) errors.push('El correo no tiene un formato válido');
}

function checkPassword(password, errors, field = 'La contraseña') {
  if (!password) errors.push(`${field} es obligatoria`);
  else if (password.length < MIN_PASSWORD) errors.push(`${field} debe tener al menos ${MIN_PASSWORD} caracteres`);
}

function throwIfErrors(errors) {
  if (errors.length) throw new ApiError(400, errors[0], errors);
}

function validateRegister(body = {}) {
  const name = text(body.name);
  const email = text(body.email).toLowerCase();
  const password = typeof body.password === 'string' ? body.password : '';
  const errors = [];
  if (name.length < 2 || name.length > 50) errors.push('El nombre debe tener entre 2 y 50 caracteres');
  checkEmail(email, errors);
  checkPassword(password, errors);
  throwIfErrors(errors);
  return { name, email, password };
}

function validateLogin(body = {}) {
  const email = text(body.email).toLowerCase();
  const password = typeof body.password === 'string' ? body.password : '';
  const errors = [];
  checkEmail(email, errors);
  if (!password) errors.push('La contraseña es obligatoria');
  throwIfErrors(errors);
  return { email, password };
}

function validateForgotPassword(body = {}) {
  const email = text(body.email).toLowerCase();
  const errors = [];
  checkEmail(email, errors);
  throwIfErrors(errors);
  return { email };
}

function validateResetPassword(body = {}) {
  const email = text(body.email).toLowerCase();
  const code = text(body.code);
  const newPassword = typeof body.newPassword === 'string' ? body.newPassword : '';
  const errors = [];
  checkEmail(email, errors);
  if (!/^\d{6}$/.test(code)) errors.push('El código debe tener 6 dígitos');
  checkPassword(newPassword, errors, 'La nueva contraseña');
  throwIfErrors(errors);
  return { email, code, newPassword };
}

module.exports = { validateRegister, validateLogin, validateForgotPassword, validateResetPassword };
