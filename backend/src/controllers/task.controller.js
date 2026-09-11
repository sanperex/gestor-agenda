const { Types } = require('mongoose');
const Task = require('../models/task.model');
const ApiError = require('../utils/ApiError');
const { sendSuccess } = require('../utils/response');
const {
  validateCreateTask,
  validateUpdateTask,
  validateTaskQuery,
  checkTaskId,
} = require('../utils/taskValidators');

// Todas estas rutas pasan por requireAuth: req.userId es el dueño de las tareas.
// Express 5 atrapa los errores de funciones async: basta con "throw".

// El texto de busqueda entra en una expresion regular. Sin escaparlo, buscar "(" rompe
// la consulta (500) y algo como ".*.*.*" pone a trabajar de mas a MongoDB.
const escapeRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// Busca por id Y por usuario: con solo el id, cualquiera con un id ajeno
// podria leer, editar o borrar la tarea de otra persona.
async function findOwnTask(userId, id) {
  const task = await Task.findOne({ _id: checkTaskId(id), userId });
  if (!task) throw new ApiError(404, 'Tarea no encontrada');
  return task;
}

// completedAt se deriva del estado; el cliente no lo manda. Asi nunca queda
// una tarea "completed" sin fecha, ni una pendiente con fecha de completada.
function applyStatus(task, status) {
  if (status === 'completed' && task.status !== 'completed') task.completedAt = new Date();
  if (status !== 'completed') task.completedAt = null;
  task.status = status;
}

// GET /api/tasks?status=pending&search=texto
async function list(req, res) {
  const { status, search } = validateTaskQuery(req.query);
  const filter = { userId: req.userId };

  if (status) filter.status = status;
  if (search) {
    const pattern = new RegExp(escapeRegex(search), 'i');
    filter.$or = [{ title: pattern }, { description: pattern }];
  }

  // Lo mas proximo primero: asi se lee una agenda.
  const tasks = await Task.find(filter).sort({ dueDate: 1 });
  sendSuccess(res, 200, { tasks }, 'Tareas obtenidas');
}

// GET /api/tasks/summary  -> cuantas tareas hay en cada estado (para los filtros de la lista)
async function summary(req, res) {
  // aggregate no convierte el id solo como find: hay que pasarlo como ObjectId.
  const groups = await Task.aggregate([
    { $match: { userId: new Types.ObjectId(req.userId) } },
    { $group: { _id: '$status', count: { $sum: 1 } } },
  ]);

  const counts = { pending: 0, inProgress: 0, completed: 0 };
  for (const g of groups) counts[g._id] = g.count;

  sendSuccess(
    res,
    200,
    { summary: { total: counts.pending + counts.inProgress + counts.completed, ...counts } },
    'Resumen de tareas'
  );
}

// GET /api/tasks/:id
async function getOne(req, res) {
  const task = await findOwnTask(req.userId, req.params.id);
  sendSuccess(res, 200, { task }, 'Tarea obtenida');
}

// POST /api/tasks
async function create(req, res) {
  const { status, ...data } = validateCreateTask(req.body);

  const task = new Task({ ...data, userId: req.userId }); // userId NUNCA viene del cliente
  applyStatus(task, status || 'pending');
  await task.save();

  sendSuccess(res, 201, { task }, 'Tarea creada');
}

// PUT /api/tasks/:id  (edicion parcial: solo cambia lo que viene en el body)
async function update(req, res) {
  const { status, ...data } = validateUpdateTask(req.body);
  const task = await findOwnTask(req.userId, req.params.id);

  task.set(data);
  if (status !== undefined) applyStatus(task, status);
  await task.save(); // save() y no findByIdAndUpdate: asi corren las validaciones del esquema

  sendSuccess(res, 200, { task }, 'Tarea actualizada');
}

// DELETE /api/tasks/:id
async function remove(req, res) {
  const task = await findOwnTask(req.userId, req.params.id);
  await task.deleteOne();
  sendSuccess(res, 200, {}, 'Tarea eliminada');
}

module.exports = { list, summary, getOne, create, update, remove };
