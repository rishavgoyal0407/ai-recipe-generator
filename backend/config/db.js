// Import dotenv package.
// dotenv allows us to load variables from the .env file
// into process.env so we can access sensitive data like
// database URLs, API keys, JWT secrets, etc.
import dotenv from 'dotenv';

// Loads all variables from .env into process.env
// Example:
// DATABASE_URL=postgres://abc...
// can now be accessed using process.env.DATABASE_URL
dotenv.config();


// Import the pg (PostgreSQL) package.
// pg provides tools to connect Node.js applications
// with PostgreSQL databases.
import pkg from 'pg';

// Extract Pool from pg.
// Pool manages multiple database connections efficiently.
// Instead of creating a new connection for every request,
// Pool reuses existing connections.
const { Pool } = pkg;


// Create a connection pool.
const pool = new Pool({

    // Database connection string from .env file.
    // Example:
    // postgres://username:password@host:5432/database
    connectionString: process.env.DATABASE_URL,

    // SSL configuration.
    // Neon PostgreSQL requires SSL connections.
    //
    // If DATABASE_URL exists:
    // ssl = { rejectUnauthorized: false }
    //
    // If DATABASE_URL doesn't exist:
    // ssl = false
    //
    // rejectUnauthorized:false means we accept
    // the server certificate without strict validation.
    ssl: process.env.DATABASE_URL
        ? { rejectUnauthorized: false }
        : false
});


// Event listener that runs whenever a new connection
// is successfully established with PostgreSQL.
pool.on('connect', () => {

    console.log('Connected to Neon PostgreSQL database');
});


// Event listener for unexpected database errors.
// This catches connection crashes or other serious issues.
pool.on('error', (err) => {

    console.log('Unexpected database error:', err);

    // Exit the Node.js application because the
    // database connection is no longer reliable.
    process.exit(-1);
});


// Export a database helper object.
// This allows other files to do:
//
// import db from './config/db.js'
//
// db.query(...)
export default {

    // Generic query function.
    // text  -> SQL query string
    // params -> values for placeholders ($1, $2, etc.)
    //
    // Example:
    // db.query(
    //   'SELECT * FROM users WHERE email = $1',
    //   ['abc@gmail.com']
    // )
    query: (text, params) => {

        // Execute SQL query using connection pool.
        return pool.query(text, params);
    },

    // Export pool directly in case you need
    // transactions or advanced PostgreSQL features.
    pool
};