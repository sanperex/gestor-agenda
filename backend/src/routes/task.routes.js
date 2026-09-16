const { Router } = require('express');
const tasks = require('../controllers/task.controller');
const requireAuth = require('../middlewares/auth.middleware');

const router = Router();

// Todas las rutas de tareas son privadas. Se aplica una vez al router para que
// ninguna ruta nueva quede abierta por olvido.
router.use(requireAuth);

// /summary va ANTES de /:id: Express prueba en orden y /:id se tragaria "summary" como id.
router.get('/summary', tasks.summary);

router.get('/', tasks.list);
router.post('/', tasks.create);
router.get('/:id', tasks.getOne);
router.put('/:id', tasks.update);
router.delete('/:id', tasks.remove);

module.exports = router;
