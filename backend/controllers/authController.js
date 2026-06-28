import User from "../models/User.js";
import UserPreference from "../models/UserPreferences.js";
import jwt from 'jsonwebtoken'

// generate jwt token

const generateToken = (user) => {
    return jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, { expiresIn: '30d' });
};


//register new user
export const register = async (req, res, next) => {

    try {

        const { email, password, name } = req.body;



        if (!email || !password || !name) {
            return res.status(400).json({
                success: false,
                message: 'Please enter the given credentials'
            })
        }

        const existingUser = await User.findByEmail(email);
        if (existingUser) {
            return res.status(400).json({
                success: false,
                message: 'User already exists with this email'
            })
        }

        const user = await User.create({ email, password, name });

        await UserPreference.upsert(user.id, {
            dietary_restrictions: [],
            allergies: [],
            preferred_cuisines: [],
            default_servings: 4,
            measurement_unit: 'metric'
        })

        const token = generateToken(user);

        res.status(201).json({
            success: true,
            message: 'User registered successfully',
            data: {
                user: {
                    id: user.id,
                    email: user.email,
                    name: user.name
                },
                token
            }
        })
    } catch (error) {
        next(error);
    }

}

// login user

export const login = async (req, res, next) => {

    try {

        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide email and password'
            })
        }

        const user = await User.findByEmail(email);
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials'
            })
        }

        const isPasswordValid = await User.verifyPassword(password, user.password_hash)

        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials'
            })
        }

        const token = generateToken(user);

        res.json({
            success: true,
            message: "Login successfully",
            data: {
                user: {
                    id: user.id,
                    email: user.email,
                    name: user.name
                },
                token
            }
        })

    } catch (error) {
        next(error);
    }

}

// get current user

export const getCurrentUser = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id);

        if (!user) {
            return res.status(404).json({
                success: false,
                messages: 'User not found'
            })
        }

        res.json({
            success: true,
            data: {
                user
            }
        })
    } catch (error) {
        next(error);
    }
}


// request for password reset

export const requestPasswordReset = async (req, res, next) => {

    try {

        const { email } = req.body;

        if (!email) {
            return res.status(400).json({
                success: false,
                message: 'please provide email'
            })
        }

        const user = await User.findByEmail(email);

        res.json({
            success: true,
            message: 'if an account exists with this email , a password reset link has been sent'
        })

    } catch (error) {
        next(error);
    }
}
