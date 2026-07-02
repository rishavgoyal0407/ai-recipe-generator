import express from 'express'

const shoppingRouter =express.Router();
import * as shoppingListController from '../controllers/shoppingListController.js'
import authMiddleware  from '../middleware/auth.js';


shoppingRouter.get('/',shoppingListController.getShoppingList);
shoppingRouter.post('/generate',shoppingListController.generateFromMealPlan);
shoppingRouter.post('/',shoppingListController.addItem);
shoppingRouter.put('/:id',shoppingListController.updateIem);
shoppingRouter.put('/:id/toggle',shoppingListController.toggleChecked);
shoppingRouter.delete('/:id',shoppingListController.deleteItem);
shoppingRouter.delete('/clear/checked',shoppingListController.clearChecked)
shoppingRouter.delete('/clear/all',shoppingListController.clearAll);
shoppingRouter.post('/add-to-pantry',shoppingListController.addCheckedToPantry);

export default shoppingRouter;