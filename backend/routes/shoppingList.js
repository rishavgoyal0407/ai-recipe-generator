import express from 'express'

const shoppingRouter =express.Router();
import * as shoppingListController from '../controllers/shoppingListController.js'
import authMiddleware  from '../middleware/auth.js';


// all routes are protected
shoppingRouter.use(authMiddleware);

shoppingRouter.get('/',shoppingListController.getShoppingList);
shoppingRouter.post('/generate',shoppingListController.generateFromMealPlan);
shoppingRouter.post('/',shoppingListController.addItem);
shoppingRouter.post('/add-to-pantry',shoppingListController.addCheckedToPantry);

// specific routes MUST come before parameterized /:id routes
shoppingRouter.delete('/clear/checked',shoppingListController.clearChecked);
shoppingRouter.delete('/clear/all',shoppingListController.clearAll);

shoppingRouter.put('/:id',shoppingListController.updateItem);
shoppingRouter.put('/:id/toggle',shoppingListController.toggleChecked);
shoppingRouter.delete('/:id',shoppingListController.deleteItem);

export default shoppingRouter;