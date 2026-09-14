const ApiError = require('./ApiError');
const { STATUSES, PRIORITIES } = require('../models/task.model');

// Mismo estilo que validators.js (Aprendiz A): se juntan todos los errores y se lanza
// un ApiError(400) con la lista. Devuelven los datos ya limpios.

const OBJECT_ID = /^[0-9a-fA-F]{24}$/;

const text = (value) => (typeof value === 'string' ? value.trim() : '');

function throwIfErrors(errors) {
  if (errors.length) throw new ApiError(400, errors[0], errors);
}

// Revisa cada campo SOLO si viene en el body. Asi sirve para crear y para editar.
function readFields(body, errors) {
  const data = {};

  if (body.title !== undefined) {
    const title = text(body.title);
    if (!title) errors.push('El título es obligatorio');
    else if (title.length > 100) errors.push('El título no puede pasar de 100 caracteres');
    data.title = title;
  }

  if (body.description !== undefined) {
    const description = text(body.description);
    if (description.length > 500) errors.push('La descripción no puede pasar de 500 caracteres');
    data.description = description;
  }

  if (body.dueDate !== undefined) {
    const dueDate = new Date(body.dueDate);
    if (typeof body.dueDate !== 'string' || Number.isNaN(dueDate.getTime())) {
      errors.push('La fecha no es válida');
    }
    data.dueDate = dueDate;
  }

  if (body.location !== undefined) {
    const location = text(body.location);
    if (location.length > 100) errors.push('La ubicación no puede pasar de 100 caracteres');
    data.location = location;
  }

  if (body.status !== undefined) {
    if (!STATUSES.includes(body.status)) errors.push(`Estado inválido. Usa: ${STATUSES.join(', ')}`);
    data.status = body.status;
  }

  if (body.priority !== undefined) {
    if (!PRIORITIES.includes(body.priority)) errors.push(`Prioridad inválida. Usa: ${PRIORITIES.join(', ')}`);
    data.priority = body.priority;
  }

  return data;
}

function validateCreateTask(body = {}) {
  const errors = [];
  // En la creacion titulo y fecha son obligatorios aunque no vengan.
  if (body.title === undefined) errors.push('El título es obligatorio');
  if (body.dueDate === undefined) errors.push('La fecha es obligatoria');
  const data = readFields(body, errors);
  throwIfErrors(errors);
  return data;
}

function validateUpdateTask(body = {}) {
  const errors = [];
  const data = readFields(body, errors);
  if (!errors.length && Object.keys(data).length === 0) errors.push('No hay datos para actualizar');
  throwIfErrors(errors);
  return data;
}

// Filtros de la lista: GET /api/tasks?status=pending&search=texto
function validateTaskQuery(query = {}) {
  const errors = [];
  const filters = {};

  if (query.status !== undefined && query.status !== '') {
    if (!STATUSES.includes(query.status)) errors.push(`Estado inválido. Usa: ${STATUSES.join(', ')}`);
    filters.status = query.status;
  }

  const search = text(query.search);
  if (search.length > 100) errors.push('La búsqueda no puede pasar de 100 caracteres');
  if (search) filters.search = search;

  throwIfErrors(errors);
  return filters;
}

// Un id mal formado responde 404 y no llega a MongoDB: si llegara, Mongoose lanza un
// CastError que el manejador de errores convierte en 500.
// No se usa isValidObjectId porque tambien acepta cualquier texto de 12 caracteres.
function checkTaskId(id) {
  if (!OBJECT_ID.test(id)) throw new ApiError(404, 'Tarea no encontrada');
  return id;
}

module.exports = { validateCreateTask, validateUpdateTask, validateTaskQuery, checkTaskId };
