import express from 'express'
const pantryRouter=express.Router();
import * as pantryController from '../controllers/pantryController.js'
import authMiddleware from '../middleware/auth.js'

// all routes are protected
pantryRouter.use(authMiddleware);

pantryRouter.get('/',pantryController.getPantryItems);
pantryRouter.get('/stats',pantryController.getPantryStats);
pantryRouter.get('/expiring-soon',pantryController.getExpiringSoon);
pantryRouter.post('/',pantryController.addPantryItem);
pantryRouter.put('/:id',pantryController.updatePantryItem);
pantryRouter.delete('/:id',pantryController.deletePantryItem);

export default pantryRouter;