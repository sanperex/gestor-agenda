// Pruebas de /api/tasks (Aprendiz B) contra un MongoDB REAL.
//
//   npm run test:tasks
//
// Usa MONGODB_URI_TEST o, si no esta, mongodb://127.0.0.1:27017/gestor_agenda_test.
// La base se BORRA al empezar y al terminar, por eso el nombre tiene que terminar en "_test":
// asi es imposible correr esto por error contra la base de Atlas con datos reales.

const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');

const TEST_URI = process.env.MONGODB_URI_TEST || 'mongodb://127.0.0.1:27017/gestor_agenda_test';
const dbName = new URL(TEST_URI.replace(/^mongodb(\+srv)?:/, 'http:')).pathname.slice(1);
if (!dbName.endsWith('_test')) {
  console.error(`La base de pruebas debe terminar en "_test" (llego "${dbName}"). No se toca nada.`);
  process.exit(1);
}

// env.js exige estas variables al cargarse: se ponen ANTES de requerir la app.
process.env.MONGODB_URI = TEST_URI;
process.env.JWT_SECRET = process.env.JWT_SECRET || 'clave-solo-para-pruebas-no-usar-en-produccion-1234';

const mongoose = require('mongoose');
const app = require('../src/app');

let server;
let base;
let tokenA;
let tokenB;

async function call(method, path, { token, body } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${base}${path}`, { method, headers, body: body ? JSON.stringify(body) : undefined });
  return { status: res.status, body: await res.json() };
}

async function registerUser(email) {
  const res = await call('POST', '/api/auth/register', { body: { name: 'Prueba', email, password: 'Clave123' } });
  assert.equal(res.status, 201, JSON.stringify(res.body));
  return res.body.data.token;
}

const newTask = (extra = {}) => ({
  title: 'Entregar informe',
  description: 'Consolidado mensual',
  dueDate: '2026-09-20T15:00:00.000Z',
  ...extra,
});

before(async () => {
  await mongoose.connect(TEST_URI);
  await mongoose.connection.dropDatabase();
  server = app.listen(0);
  base = `http://127.0.0.1:${server.address().port}`;
  tokenA = await registerUser('a@prueba.com');
  tokenB = await registerUser('b@prueba.com');
});

after(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
  server.close();
});

test('sin token responde 401', async () => {
  const res = await call('GET', '/api/tasks');
  assert.equal(res.status, 401);
  assert.equal(res.body.success, false);
});

test('crea una tarea con el formato comun { success, message, data }', async () => {
  const res = await call('POST', '/api/tasks', { token: tokenA, body: newTask({ priority: 'high' }) });
  assert.equal(res.status, 201);
  assert.equal(res.body.success, true);
  const { task } = res.body.data;
  assert.match(task.id, /^[0-9a-f]{24}$/);
  assert.equal(task._id, undefined);
  assert.equal(task.status, 'pending');
  assert.equal(task.priority, 'high');
  assert.equal(task.completedAt, null);
});

test('el userId sale del token aunque el cliente mande otro', async () => {
  const intruso = '0123456789abcdef01234567';
  const res = await call('POST', '/api/tasks', { token: tokenA, body: newTask({ userId: intruso }) });
  assert.equal(res.status, 201);
  assert.notEqual(res.body.data.task.userId, intruso);
});

test('valida titulo, fecha, estado y prioridad', async () => {
  let res = await call('POST', '/api/tasks', { token: tokenA, body: { dueDate: '2026-09-20T15:00:00Z' } });
  assert.equal(res.status, 400);
  assert.ok(res.body.errors.includes('El título es obligatorio'));

  res = await call('POST', '/api/tasks', { token: tokenA, body: newTask({ dueDate: 'mañana' }) });
  assert.equal(res.status, 400);

  res = await call('POST', '/api/tasks', { token: tokenA, body: newTask({ status: 'inventado' }) });
  assert.equal(res.status, 400);

  res = await call('POST', '/api/tasks', { token: tokenA, body: newTask({ priority: 'urgente' }) });
  assert.equal(res.status, 400);

  res = await call('POST', '/api/tasks', { token: tokenA, body: newTask({ title: 'x'.repeat(101) }) });
  assert.equal(res.status, 400);
});

test('lista solo las tareas propias, ordenadas por fecha', async () => {
  await call('POST', '/api/tasks', {
    token: tokenA,
    body: newTask({ title: 'Reunión de equipo', description: 'Revisión de sprint', dueDate: '2026-09-05T09:00:00Z' }),
  });

  const res = await call('GET', '/api/tasks', { token: tokenA });
  assert.equal(res.status, 200);
  const { tasks } = res.body.data;
  assert.equal(tasks.length, 3);
  assert.equal(tasks[0].title, 'Reunión de equipo');

  const otro = await call('GET', '/api/tasks', { token: tokenB });
  assert.equal(otro.body.data.tasks.length, 0);
});

test('filtra por estado y busca sin distinguir mayusculas', async () => {
  let res = await call('GET', '/api/tasks?search=SPRINT', { token: tokenA });
  assert.equal(res.body.data.tasks.length, 1);

  res = await call('GET', '/api/tasks?search=consolidado', { token: tokenA });
  assert.equal(res.body.data.tasks.length, 2, 'busca tambien en la descripcion');

  res = await call('GET', '/api/tasks?status=completed', { token: tokenA });
  assert.equal(res.body.data.tasks.length, 0);

  res = await call('GET', '/api/tasks?status=raro', { token: tokenA });
  assert.equal(res.status, 400);
});

test('un parentesis en la busqueda no rompe la consulta', async () => {
  const res = await call('GET', `/api/tasks?search=${encodeURIComponent('a(b')}`, { token: tokenA });
  assert.equal(res.status, 200);
});

test('editar es parcial y el estado decide completedAt', async () => {
  const { body } = await call('GET', '/api/tasks', { token: tokenA });
  const id = body.data.tasks[1].id;

  let res = await call('PUT', `/api/tasks/${id}`, { token: tokenA, body: { title: 'Informe (v2)' } });
  assert.equal(res.status, 200);
  assert.equal(res.body.data.task.title, 'Informe (v2)');
  assert.equal(res.body.data.task.description, 'Consolidado mensual', 'no borra lo que no vino');

  res = await call('PUT', `/api/tasks/${id}`, { token: tokenA, body: { status: 'completed' } });
  assert.ok(res.body.data.task.completedAt, 'completed pone fecha');

  res = await call('PUT', `/api/tasks/${id}`, { token: tokenA, body: { status: 'pending' } });
  assert.equal(res.body.data.task.completedAt, null, 'volver a pending la borra');

  res = await call('PUT', `/api/tasks/${id}`, { token: tokenA, body: {} });
  assert.equal(res.status, 400, 'un body vacio no es una edicion');
});

test('el resumen cuenta por estado', async () => {
  const { body } = await call('GET', '/api/tasks', { token: tokenA });
  await call('PUT', `/api/tasks/${body.data.tasks[0].id}`, { token: tokenA, body: { status: 'completed' } });

  const res = await call('GET', '/api/tasks/summary', { token: tokenA });
  assert.equal(res.status, 200, '/summary no lo captura /:id');
  assert.deepEqual(res.body.data.summary, { total: 3, pending: 2, inProgress: 0, completed: 1 });
});

test('otro usuario no puede leer, editar ni borrar una tarea ajena', async () => {
  const { body } = await call('GET', '/api/tasks', { token: tokenA });
  const id = body.data.tasks[0].id;

  assert.equal((await call('GET', `/api/tasks/${id}`, { token: tokenB })).status, 404);
  assert.equal((await call('PUT', `/api/tasks/${id}`, { token: tokenB, body: { title: 'hackeado' } })).status, 404);
  assert.equal((await call('DELETE', `/api/tasks/${id}`, { token: tokenB })).status, 404);
});

test('un id mal formado responde 404, no 500', async () => {
  const res = await call('GET', '/api/tasks/abc', { token: tokenA });
  assert.equal(res.status, 404);
});

test('eliminar borra la tarea', async () => {
  const { body } = await call('GET', '/api/tasks', { token: tokenA });
  const id = body.data.tasks[0].id;

  const res = await call('DELETE', `/api/tasks/${id}`, { token: tokenA });
  assert.equal(res.status, 200);
  assert.equal((await call('GET', `/api/tasks/${id}`, { token: tokenA })).status, 404);
});
