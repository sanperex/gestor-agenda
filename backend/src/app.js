const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const { corsOrigin } = require('./config/env');
const authRoutes = require('./routes/auth.routes');
const { notFound, errorHandler } = require('./middlewares/error.middleware');

const app = express();

app.use(cors({ origin: corsOrigin })); // permite que Flutter Web llame a la API desde otro dominio
app.use(express.json({ limit: '10kb' })); // lee el cuerpo JSON de las peticiones

// Para Railway y para comprobar rapido que la API y la base de datos estan vivas.
app.get('/api/health', (_req, res) => {
  const db = mongoose.connection.readyState === 1 ? 'conectada' : 'desconectada';
  res.json({ success: true, message: 'API funcionando', data: { db } });
});

app.use('/api/auth', authRoutes); // Aprendiz A
// Aprendiz B: app.use('/api/tasks', taskRoutes);

app.use(notFound);
app.use(errorHandler); // siempre al final

module.exports = app;
