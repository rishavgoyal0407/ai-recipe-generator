/*
===============================================================================
AUTHENTICATION MIDDLEWARE
===============================================================================

Purpose:
Protects private routes by verifying JWT tokens.

Responsibilities:
- Extract token from request headers
- Verify token authenticity
- Attach user information to request
- Block unauthorized access

Used Before:
- Profile routes
- Pantry routes
- Recipe routes
- Meal planning routes

Flow:

Client Request
      ↓
Authorization Header
      ↓
Verify JWT
      ↓
Extract User Data
      ↓
Attach req.user
      ↓
Allow Access

===============================================================================
*/

import jwt from 'jsonwebtoken';

/*
|--------------------------------------------------------------------------
| Authentication Middleware
|--------------------------------------------------------------------------
|
| Runs before protected route handlers.
|
| If token is valid:
|     Continue request
|
| If token is missing/invalid:
|     Return 401 Unauthorized
|
*/
const authMiddleware = async (req, res, next) => {

    try {

        /*
        Extract JWT token from Authorization header.

        Example Header:

        Authorization: Bearer eyJhbGciOiJIUzI1...

        Remove "Bearer " and keep only token.
        */
        const token = req
            .header('Authorization')
            ?.replace('Bearer ', '');

        /*
        Token is required for accessing
        protected resources.
        */
        if (!token) {

            return res.status(401).json({
                success: false,
                message: 'No authentication token, access denied'
            });
        }

        /*
        Verify token signature using JWT_SECRET.

        If token:
        - is modified
        - is expired
        - has invalid signature

        jwt.verify() throws an error.
        */
        const decoded = jwt.verify(
            token,
            process.env.JWT_SECRET
        );

        /*
        Store authenticated user information
        inside request object.

        Makes user data available in all
        subsequent controllers.

        Example:

        req.user.id
        req.user.email
        */
        req.user = {
            id: decoded.id,
            email: decoded.email
        };

        /*
        Pass control to next middleware
        or route handler.
        */
        next();

    } catch (error) {

        /*
        Common Causes:

        - Invalid token
        - Expired token
        - Tampered token
        - Wrong JWT secret
        */
        console.error(
            'Auth middleware error:',
            error
        );

        res.status(401).json({
            success: false,
            message: 'Token is not valid'
        });
    }
};

export default authMiddleware;