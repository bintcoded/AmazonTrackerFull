// api.js — Shared API helper for all frontend pages
// Connects HTML pages to the Express backend via fetch()

const API = 'http://localhost:3000';

// ── Generic fetch wrapper ─────────────────────────────────────
async function apiFetch(endpoint, options = {}) {
  try {
    const res = await fetch(`${API}${endpoint}`, {
      headers: { 'Content-Type': 'application/json' },
      ...options
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Request failed');
    return data;
  } catch (err) {
    console.error(`API error [${endpoint}]:`, err.message);
    throw err;
  }
}

// ── Species CRUD ──────────────────────────────────────────────
const SpeciesAPI = {
  // GET all species (with optional filters)
  getAll: (params = {}) => {
    const qs = new URLSearchParams(params).toString();
    return apiFetch('/species' + (qs ? '?' + qs : ''));
  },

  // GET one species by ID
  getOne: (id) => apiFetch(`/species/${id}`),

  // POST — create new species
  create: (data) => apiFetch('/species', {
    method: 'POST',
    body: JSON.stringify(data)
  }),

  // PUT — update existing species
  update: (id, data) => apiFetch(`/species/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  }),

  // DELETE — remove species
  remove: (id) => apiFetch(`/species/${id}`, { method: 'DELETE' })
};

// ── Lookup tables ─────────────────────────────────────────────
const LookupAPI = {
  getOrganismTypes: () => apiFetch('/organismtypes'),
  getStatuses:      () => apiFetch('/statuses'),
  getRegions:       () => apiFetch('/regions'),
  getThreats:       () => apiFetch('/threats')
};

// ── Helper: populate a <select> from API ─────────────────────
async function populateSelect(selectId, items, valueKey, labelKey, placeholder = '-- Select --') {
  const el = document.getElementById(selectId);
  if (!el) return;
  el.innerHTML = `<option value="">${placeholder}</option>`;
  items.forEach(item => {
    const opt = document.createElement('option');
    opt.value = item[valueKey];
    opt.textContent = item[labelKey];
    el.appendChild(opt);
  });
}

// ── Helper: show alert message ────────────────────────────────
function showAlert(elementId, message, type = 'success') {
  const el = document.getElementById(elementId);
  if (!el) return;
  el.textContent = message;
  el.className = `alert alert-${type} show`;
  setTimeout(() => el.classList.remove('show'), 5000);
}
