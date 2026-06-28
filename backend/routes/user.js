import express from 'express'

const router=express.Router();
import authMiddleware from '../middleware/auth.js';

import * as userController from '../controllers/userController.js'

// all routes are protected

router.use(authMiddleware);

router.get('/profile',userController.getProfile);
router.put('/profile',userController.updateProfile);
router.put('/preferences',userController.updatePreferences);
router.put('/change-password',userController.changePassword);
router.delete('/account',userController.deleteAccount);

export default router;