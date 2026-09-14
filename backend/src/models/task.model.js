const { Schema, model } = require('mongoose');

// Valores permitidos. Se exportan porque los validadores y el Flutter usan los mismos.
const STATUSES = ['pending', 'inProgress', 'completed'];
const PRIORITIES = ['low', 'medium', 'high'];

// Coleccion "tareas" (Aprendiz B). Cada tarea pertenece a un usuario de la coleccion "usuarios".
const taskSchema = new Schema(
  {
    // Sale SIEMPRE del token (req.userId), nunca del cuerpo de la peticion.
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    title: { type: String, required: true, trim: true, maxlength: 100 },
    description: { type: String, trim: true, maxlength: 500, default: '' },
    dueDate: { type: Date, required: true },
    location: { type: String, trim: true, maxlength: 100, default: '' },
    status: { type: String, enum: STATUSES, default: 'pending' },
    priority: { type: String, enum: PRIORITIES, default: 'medium' },
    // Lo pone el controlador al pasar a "completed" y lo borra al salir de ese estado.
    completedAt: { type: Date, default: null },
  },
  { timestamps: true } // agrega createdAt y updatedAt
);

// La consulta de la lista: las tareas de un usuario ordenadas por fecha.
taskSchema.index({ userId: 1, dueDate: 1 });

// Lo que se envia al cliente: "id" en vez de "_id", igual que en usuarios.
taskSchema.set('toJSON', {
  transform: (_doc, ret) => {
    ret.id = ret._id.toString();
    ret.userId = ret.userId.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

// Tercer parametro: nombre exacto de la coleccion en MongoDB Atlas.
module.exports = model('Task', taskSchema, 'tareas');
module.exports.STATUSES = STATUSES;
module.exports.PRIORITIES = PRIORITIES;
