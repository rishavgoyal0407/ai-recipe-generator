// Load environment variables from .env file
// Makes values like DATABASE_URL available through process.env
import dotenv from 'dotenv'

// Used to read files from the filesystem
// Needed to load schema.sql during migration
import fs from 'fs'

// Helps build file paths that work on Windows, Linux, and Mac
import path from 'path'

// Converts ES module URLs into normal file paths
// Needed because __dirname doesn't exist in ES modules
import { fileURLToPath } from 'url'

// PostgreSQL package
import pkg from 'pg'

// Extract Pool class from pg package
// Pool manages database connections efficiently
const { Pool } = pkg;

// Current file path (equivalent of __filename in CommonJS)
const __filename = fileURLToPath(import.meta.url);

// Current directory path (equivalent of __dirname in CommonJS)
const __dirname = path.dirname(__filename);

// Load variables from .env into process.env
dotenv.config();

/*
|--------------------------------------------------------------------------
| Database Connection Pool
|--------------------------------------------------------------------------
|
| Creates a reusable pool of PostgreSQL connections.
| Reusing connections is much faster than creating a new
| database connection for every query.
|
*/
const pool = new Pool({

    // Database connection string stored in .env
    connectionString: process.env.DATABASE_URL,

    /*
    SSL configuration.

    Required by cloud databases such as Neon.

    rejectUnauthorized: false
    allows connection even when a local certificate
    cannot be verified.
    */
    ssl: process.env.DATABASE_URL
        ? { rejectUnauthorized: false }
        : false
});

/*
|--------------------------------------------------------------------------
| Run Database Migration
|--------------------------------------------------------------------------
|
| Reads schema.sql and executes all SQL statements.
|
| Purpose:
| Create tables, indexes, functions and triggers
| automatically from a single schema file.
|
*/
async function runMigration() {

    // Get a database connection from the pool
    const client = await pool.connect();

    try {

        console.log('running database migration...');

        /*
        Locate schema.sql file.

        __dirname points to:
            backend/utils

        '..' moves one folder up:
            backend

        Final path:
            backend/config/schema.sql
        */
        const schemaPath = path.join(
            __dirname,
            '..',
            'config',
            'schema.sql'
        );

        /*
        Read complete SQL schema into memory.

        utf8 ensures file is returned as text
        instead of binary data.
        */
        const schemaSql = fs.readFileSync(
            schemaPath,
            'utf8'
        );

        /*
        Execute all SQL statements.

        This creates:

        - Tables
        - Indexes
        - Functions
        - Triggers
        */
        await client.query(schemaSql);

        console.log('Database migration completed successfully');

        console.log('Tables created:');
        console.log('- users');
        console.log('- user_preferences');
        console.log('- pantry_items');
        console.log('- recipes');
        console.log('- recipe_ingredients');
        console.log('- recipe_nutrition');
        console.log('- meal_plans');
        console.log('- shopping_list_items');

    } catch (error) {

        /*
        If any SQL statement fails,
        show the error and stop execution.

        Example:
            Syntax errors
            Missing tables
            Invalid constraints
        */
        console.error(
            'Migration failed:',
            error.message
        );

        process.exit(1);

    } finally {

        /*
        Always release connection back to pool.

        Without this, connections may remain open
        and eventually exhaust the pool.
        */
        client.release();

        /*
        Close all pool connections.

        Since migration is a one-time script,
        keeping connections open is unnecessary.
        */
        await pool.end();
    }
}

// Start migration process
runMigration();