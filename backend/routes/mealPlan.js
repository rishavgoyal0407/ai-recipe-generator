import express from 'express'
const mealRouter=express.Router();
import * as mealPlanController from '../controllers/mealPlanController.js'

import authMiddleware from '../middleware/auth.js'

// all routes are protected
mealRouter.use(authMiddleware);

mealRouter.get('/weekly',mealPlanController.getWeeklyMealPlan);
mealRouter.get('/upcoming',mealPlanController.getUpcomingMeals);
mealRouter.get('/stats',mealPlanController.getMealPlanStats);
mealRouter.post('/',mealPlanController.addToMealPlan);
mealRouter.delete('/:id',mealPlanController.deleteMealPlan);

export default mealRouter;