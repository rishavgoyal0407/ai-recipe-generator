import express from 'express'

const authRouter=express.Router();
import authMiddleware from '../middleware/auth.js';

import * as authController from '../controllers/authController.js'


//public routes
// no need of token before

authRouter.post('/signup',authController.register);
authRouter.post('/login',authController.login);
authRouter.post('/reset-password',authController.requestPasswordReset);


// protected routes
authRouter.get('/me',authMiddleware,authController.getCurrentUser);

export default authRouter;