// Database helper used to execute PostgreSQL queries
import db from '../config/db.js'

// Used for securely hashing and verifying passwords
// Never store plain-text passwords in the database
import bcrypt from 'bcryptjs'

class User {

    /*
    |--------------------------------------------------------------------------
    | Create User
    |--------------------------------------------------------------------------
    |
    | Creates a new user account.
    |
    | Before storing the user:
    | - Password is hashed for security
    | - Only safe user data is returned
    |
    */
    static async create({ email, password, name }) {

        // Convert plain password into secure hash
        const hashedPassword = await bcrypt.hash(password, 10);

        // Insert user into database
        const result = await db.query(
            `INSERT INTO users (email,password_hash,name)
             VALUES($1,$2,$3)
             RETURNING id,email,name,created_at`,
            [email, hashedPassword, name]
        );

        return result.rows[0];
    }

    /*
    |--------------------------------------------------------------------------
    | Find User By Email
    |--------------------------------------------------------------------------
    |
    | Used during login.
    |
    | Email is unique, so at most one user
    | can be returned.
    |
    */
    static async findByEmail(email) {

        const result = await db.query(
            'SELECT * FROM users WHERE email = $1',
            [email]
        );

        return result.rows[0];
    }

    /*
    |--------------------------------------------------------------------------
    | Find User By ID
    |--------------------------------------------------------------------------
    |
    | Commonly used after JWT authentication.
    |
    | Returns public profile information
    | without exposing password hash.
    |
    */
    static async findById(id) {

        const result = await db.query(
            `SELECT id,email,name,created_at,updated_at
             FROM users
             WHERE id = $1`,
            [id]
        );

        return result.rows[0];
    }

    /*
    |--------------------------------------------------------------------------
    | Update User Profile
    |--------------------------------------------------------------------------
    |
    | Updates name and/or email.
    |
    | COALESCE allows partial updates.
    |
    | Example:
    | update({ name: "John" })
    |
    | Email remains unchanged.
    |
    */
    static async update(id, updates) {

        const { name, email } = updates;

        const result = await db.query(
            `UPDATE users
             SET
                name = COALESCE($1, name),
                email = COALESCE($2, email)
             WHERE id = $3
             RETURNING id,email,name,updated_at`,
            [name, email, id]
        );

        return result.rows[0];
    }

    /*
    |--------------------------------------------------------------------------
    | Update Password
    |--------------------------------------------------------------------------
    |
    | Passwords are never stored directly.
    |
    | Every new password is hashed before
    | saving to the database.
    |
    */
    static async updatePassword(id, newPassword) {

        const hashedPassword =
            await bcrypt.hash(newPassword, 10);

        await db.query(
            `UPDATE users
             SET password_hash = $1
             WHERE id = $2`,
            [hashedPassword, id]
        );
    }

    /*
    |--------------------------------------------------------------------------
    | Verify Password
    |--------------------------------------------------------------------------
    |
    | Compares login password with
    | stored password hash.
    |
    | Returns:
    | true  -> password matches
    | false -> invalid password
    |
    */
    static async verifyPassword(
        plainPassword,
        hashedPassword
    ) {

        return await bcrypt.compare(
            plainPassword,
            hashedPassword
        );
    }

    /*
    |--------------------------------------------------------------------------
    | Delete User
    |--------------------------------------------------------------------------
    |
    | Removes user account permanently.
    |
    | Related records are automatically removed
    | because database tables use
    | ON DELETE CASCADE.
    |
    */
    static async delete(id) {

        await db.query(
            'DELETE FROM users WHERE id = $1',
            [id]
        );
    }
}

export default User;