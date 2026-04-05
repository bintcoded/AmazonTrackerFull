//  server.js — Amazon Species Tracker Backend
//  Express + PostgreSQL (pg library)
//  server.js — Amazon Species Tracker Backend
//  Express + PostgreSQL (pg library)
console.log("HELLO FROM SERVER");
console.log("STARTING SERVER...");
const express = require('express');
const cors    = require('cors');
require('dotenv').config();

const pool = require('./db');
const app  = express();
const PORT = process.env.PORT || 3000;


app.use(cors());                 // allow frontend HTML pages to call this API
app.use(express.json());         // parse JSON request bodies

// test route to verify server is running
app.get('/', (req, res) => {
  res.send('API is running');
});

//  LOOKUP ROUTES (used to populate dropdowns in forms) 

// GET /organismtypes  → all animal types
app.get('/organismtypes', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT organismtypeid, type FROM public.organismtype ORDER BY type'
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /statuses 
app.get('/statuses', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT statusid, statusvalue, risklevel FROM public.status ORDER BY risklevel'
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /regions : all Amazon regions
app.get('/regions', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT regionid, regionname FROM public.region ORDER BY regionname'
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /threats  : all threat types
app.get('/threats', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT threatid, threatname FROM public.threat ORDER BY threatname'
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// GET /species
// Returns all species with joined lookup values.
// Optional query params: ?type=Mammal  ?status=Vulnerable  ?region=Brazilian+Amazon
app.get('/species', async (req, res) => {
  try {
    const { type, status, region, search } = req.query;

    let query = `
      SELECT
        s.speciesid,
        s.commonname,
        s.scientificname,
        o.type          AS animaltype,
        st.statusvalue  AS status,
        st.risklevel,
        r.regionname    AS region,
        s.habitat,
        COALESCE(
          string_agg(DISTINCT t.threatname, ', ' ORDER BY t.threatname),
          'None listed'
        ) AS threats
      FROM public.species s
      JOIN public.organismtype o  ON s.organismtypeid = o.organismtypeid
      JOIN public.status st       ON s.statusid       = st.statusid
      JOIN public.region r        ON s.regionid       = r.regionid
      LEFT JOIN public.speciesthreats sth ON s.speciesid = sth.speciesid
      LEFT JOIN public.threat t           ON sth.threatid = t.threatid
      WHERE 1=1
    `;

    const params = [];

    if (type) {
      params.push(type);  
      query += ` AND o.type = $${params.length}`;
    }
    if (status) {
      params.push(`%${status}%`);
      query += ` AND st.statusvalue ILIKE $${params.length}`;
    }
    if (region) {
      params.push(region);
      query += ` AND r.regionname = $${params.length}`;
    }
    if (search) {
      params.push(`%${search}%`);
      const searchIdx = params.length;
      params.push(`%${search}%`);
      query += ` AND (s.commonname ILIKE $${searchIdx} OR s.scientificname ILIKE $${params.length})`;
    }

    query += `
      GROUP BY s.speciesid, s.commonname, s.scientificname,
               o.type, st.statusvalue, st.risklevel,
               r.regionname, s.habitat
      ORDER BY CASE WHEN st.risklevel = 0 THEN 999 ELSE st.risklevel END ASC, s.commonname ASC
    `;

    const result = await pool.query(query, params);
    res.json(result.rows);

  } catch (err) {
    console.error('GET /species error:', err.message);
    res.status(500).json({ error: err.message });
  }
});


// GET /species/:id
// Returns a single species record with all joined data and its associated threats.
app.get('/species/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const speciesResult = await pool.query(`
      SELECT
        s.speciesid,
        s.commonname,
        s.scientificname,
        s.organismtypeid,
        o.type         AS animaltype,
        s.statusid,
        st.statusvalue AS status,
        st.risklevel,
        s.regionid,
        r.regionname   AS region,
        s.habitat
      FROM public.species s
      JOIN public.organismtype o ON s.organismtypeid = o.organismtypeid
      JOIN public.status st      ON s.statusid       = st.statusid
      JOIN public.region r       ON s.regionid       = r.regionid
      WHERE s.speciesid = $1
    `, [id]);

    if (speciesResult.rows.length === 0) {
      return res.status(404).json({ error: 'Species not found' });
    }

    // Also fetch threats for this species
    const threatsResult = await pool.query(`
      SELECT t.threatid, t.threatname
      FROM public.speciesthreats sth
      JOIN public.threat t ON sth.threatid = t.threatid
      WHERE sth.speciesid = $1
      ORDER BY t.threatname
    `, [id]);

    const species = speciesResult.rows[0];
    species.threats = threatsResult.rows;

    res.json(species);

  } catch (err) {
    console.error('GET /species/:id error:', err.message);
    res.status(500).json({ error: err.message });
  }
});


// POST /species
// Insert a new species record
// Body: { commonname, scientificname, organismtypeid, statusid, regionid, habitat, threatids[] }
// Note: threatids is an optional array of threat IDs to link to this species.
app.post('/species', async (req, res) => {
  const client = await pool.connect();
  try {
    const {
      commonname,
      scientificname,
      organismtypeid,
      statusid,
      regionid,
      habitat,
      threatids   // optional array of threat IDs
    } = req.body;

    // Validate required fields
    if (!commonname || !scientificname || !organismtypeid || !statusid || !regionid) {
      return res.status(400).json({
        error: 'Missing required fields: commonname, scientificname, organismtypeid, statusid, regionid'
      });
    }

    await client.query('BEGIN');

    // Get the next available speciesid
    const maxIdResult = await client.query('SELECT COALESCE(MAX(speciesid), 0) + 1 AS nextid FROM public.species');
    const nextId = maxIdResult.rows[0].nextid;

    // INSERT into species
    const insertResult = await client.query(`
      INSERT INTO public.species
        (speciesid, commonname, scientificname, organismtypeid, statusid, regionid, habitat)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [nextId, commonname, scientificname, organismtypeid, statusid, regionid, habitat || null]);

    const newSpecies = insertResult.rows[0];

    // INSERT threat links if provided
    if (Array.isArray(threatids) && threatids.length > 0) {
      for (const threatid of threatids) {
        await client.query(
          'INSERT INTO public.speciesthreats (speciesid, threatid) VALUES ($1, $2)',
          [nextId, threatid]
        );
      }
    }

    await client.query('COMMIT');

    res.status(201).json({
      message: 'Species added successfully',
      species: newSpecies
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('POST /species error:', err.message);
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});


// PUT /species/:id
// Update an existing species record
// Body: { commonname, scientificname, organismtypeid, statusid, regionid, habitat, threatids[] }
app.put('/species/:id', async (req, res) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;
    const {
      commonname,
      scientificname,
      organismtypeid,
      statusid,
      regionid,
      habitat,
      threatids
    } = req.body;

    // Check species exists
    const check = await client.query('SELECT speciesid FROM public.species WHERE speciesid = $1', [id]);
    if (check.rows.length === 0) {
      return res.status(404).json({ error: 'Species not found' });
    }

    await client.query('BEGIN');

    // UPDATE species record
    const updateResult = await client.query(`
      UPDATE public.species
      SET
        commonname     = COALESCE($1, commonname),
        scientificname = COALESCE($2, scientificname),
        organismtypeid = COALESCE($3, organismtypeid),
        statusid       = COALESCE($4, statusid),
        regionid       = COALESCE($5, regionid),
        habitat        = COALESCE($6, habitat)
      WHERE speciesid = $7
      RETURNING *
    `, [commonname, scientificname, organismtypeid, statusid, regionid, habitat, id]);

    // If new threat list provided, replace all existing threat links
    if (Array.isArray(threatids)) {
      await client.query('DELETE FROM public.speciesthreats WHERE speciesid = $1', [id]);
      for (const threatid of threatids) {
        await client.query(
          'INSERT INTO public.speciesthreats (speciesid, threatid) VALUES ($1, $2)',
          [id, threatid]
        );
      }
    }

    await client.query('COMMIT');

    res.json({
      message: 'Species updated successfully',
      species: updateResult.rows[0]
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('PUT /species/:id error:', err.message);
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// DELETE /species/:id
// Remove a species and its threat links
app.delete('/species/:id', async (req, res) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;

    // Check species exists
    const check = await client.query(
      'SELECT speciesid, commonname FROM public.species WHERE speciesid = $1', [id]
    );
    if (check.rows.length === 0) {
      return res.status(404).json({ error: 'Species not found' });
    }

    const speciesName = check.rows[0].commonname;

    await client.query('BEGIN');

    // Step 1: Delete child records (foreign key constraint)
    await client.query('DELETE FROM public.speciesthreats WHERE speciesid = $1', [id]);

    // Step 2: Delete the species itself
    await client.query('DELETE FROM public.species WHERE speciesid = $1', [id]);

    await client.query('COMMIT');

    res.json({
      message: `Species "${speciesName}" (ID: ${id}) deleted successfully`
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('DELETE /species/:id error:', err.message);
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});



// Start server
app.listen(PORT, () => {
  console.log(`\n🌿 Amazon Species Tracker backend running`);
  console.log(`   → http://localhost:${PORT}`);
  console.log(`   → API: http://localhost:${PORT}/species\n`);
});