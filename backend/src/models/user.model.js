const { Schema, model } = require('mongoose');

// Coleccion "usuarios". El _id que crea MongoDB es el userId que usara la coleccion tasks (Aprendiz B).
const userSchema = new Schema(
  {
    name: { type: String, required: true, trim: true, minlength: 2, maxlength: 50 },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    // Hash de bcrypt, nunca texto plano. select:false = no sale en las consultas salvo que se pida.
    password: { type: String, required: true, select: false },
    // Recuperacion de contraseña: hash del código, vencimiento e intentos fallidos.
    resetCodeHash: { type: String, select: false },
    resetCodeExpires: { type: Date, select: false },
    resetAttempts: { type: Number, default: 0, select: false },
  },
  { timestamps: true } // agrega createdAt y updatedAt
);

// Lo que se envia al cliente: "id" en vez de "_id" y nada sensible.
userSchema.set('toJSON', {
  transform: (_doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    delete ret.password;
    delete ret.resetCodeHash;
    delete ret.resetCodeExpires;
    delete ret.resetAttempts;
    return ret;
  },
});

// Tercer parametro: nombre exacto de la coleccion en MongoDB Atlas.
module.exports = model('User', userSchema, 'usuarios');
