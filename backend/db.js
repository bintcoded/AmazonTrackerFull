// db.js — PostgreSQL connection pool
// Uses the 'pg' library and reads credentials from .env

const { Pool } = require('pg');

const isProduction = process.env.DATABASE_URL;

const pool = new Pool(
  isProduction
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: {
          rejectUnauthorized: false
        }
      }
    : {
        host: 'localhost',
        port: 5432,
        database: 'amazon_species',
        user: 'postgres',
        password: '1234'
      }
);

// optional test connection
pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ DB connection failed:', err.message);
  } else {
    console.log('✅ Connected to PostgreSQL');
    release();
  }
});

module.exports = pool;