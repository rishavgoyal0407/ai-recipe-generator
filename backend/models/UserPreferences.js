/*
===============================================================================
USER PREFERENCE MODEL
===============================================================================

Purpose:
Manages user food preferences and dietary settings.

Responsibilities:
- Create preferences
- Update preferences
- Retrieve preferences
- Delete preferences

Used by:
- Recipe recommendations
- Meal planning
- Dietary filtering
- Personalized recipe generation
===============================================================================
*/

import db from "../config/db.js";

class UserPreference {

    /*
    |--------------------------------------------------------------------------
    | Create or Update Preferences
    |--------------------------------------------------------------------------
    |
    | Uses PostgreSQL UPSERT pattern.
    |
    | If preferences don't exist:
    |     INSERT a new row
    |
    | If preferences already exist:
    |     UPDATE existing row
    |
    | This prevents duplicate preference records
    | for the same user.
    |
    */
    static async upsert(userId, preferences) {

        /*
        Default values ensure the application
        always has valid preference data even if
        some fields are omitted.
        */
        const {
            dietary_restrictions = [],
            allergies = [],
            preferred_cuisines = [],
            default_servings = 4,
            measurement_unit = 'metric'
        } = preferences;

        const result = await db.query(
            `
            INSERT INTO user_preferences(
                user_id,
                dietary_restrictions,
                allergies,
                preferred_cuisines,
                default_servings,
                measurement_unit
            )
            VALUES($1,$2,$3,$4,$5,$6)

            /*
            user_id is UNIQUE in the database.

            ON CONFLICT handles the case where
            a user already has preferences.

            Instead of throwing an error,
            PostgreSQL updates the existing row.
            */
            ON CONFLICT (user_id)
            DO UPDATE SET
                dietary_restrictions = $2,
                allergies = $3,
                preferred_cuisines = $4,
                default_servings = $5,
                measurement_unit = $6

            /*
            Return the latest version of the row
            after insert/update.
            */
            RETURNING *
            `,
            [
                userId,
                dietary_restrictions,
                allergies,
                preferred_cuisines,
                default_servings,
                measurement_unit
            ]
        );

        return result.rows[0];
    }

    /*
    |--------------------------------------------------------------------------
    | Find Preferences By User ID
    |--------------------------------------------------------------------------
    |
    | Retrieves preference settings belonging
    | to a specific user.
    |
    | Used when:
    | - Loading user profile
    | - Generating recipes
    | - Building meal plans
    |
    */
    static async findByUserId(userId) {

        const result = await db.query(
            'SELECT * FROM user_preferences WHERE user_id = $1',
            [userId]
        );

        /*
        Return null when preferences do not exist.
        Makes error handling easier for callers.
        */
        return result.rows[0] || null;
    }

    /*
    |--------------------------------------------------------------------------
    | Delete Preferences
    |--------------------------------------------------------------------------
    |
    | Removes all stored preferences for a user.
    |
    | Typically used during:
    | - Account deletion
    | - Preference reset
    |
    */
    static async delete(userId) {

        await db.query(
            'DELETE FROM user_preferences WHERE user_id = $1',
            [userId]
        );
    }
}

export default UserPreference;