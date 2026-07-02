import express from 'express'
const recipeRouter=express.Router();
import * as recipeController from '../controllers/recipeController.js'
import authMiddleware from '../middleware/auth.js';

// all routes are protected

recipeRouter.use(authMiddleware);

// AI generation
recipeRouter.post('/generate',recipeController.generateRecipe);
recipeController.get('/suggestions',recipeController.getPantrySuggestions);

// CRUD operations

recipeRouter.get('/',recipeController.getRecipes);
recipeRouter.get('/recent',recipeController.getRecentRecipes);
recipeRouter.get('/stats',recipeController.getRecipeStats);
recipeRouter.get('/:id',recipeController.getRecipeById);
recipeRouter.post('/',recipeController.saveRecipe);
recipeRouter.put('/:id',recipeController.updateRecipe);
recipeRouter.delete('/:id',recipeController.deleteRecipe)

export default recipeRouter;