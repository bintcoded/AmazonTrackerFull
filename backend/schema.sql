-- ============================================================
--  Amazon Species Database — PostgreSQL Schema + Seed Data
--  Wayne State University · Database Course 2026
--  Team: Natalia Dycha & Sara Al-Hachami
-- ============================================================

-- Run this file in pgAdmin Query Tool or via:
--   psql -U postgres -d "Amazon Species" -f schema.sql

-- ─────────────────────────────────────────────────────────────
-- DROP existing tables (safe re-run)
-- ─────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS public.speciesthreats CASCADE;
DROP TABLE IF EXISTS public.species       CASCADE;
DROP TABLE IF EXISTS public.threat        CASCADE;
DROP TABLE IF EXISTS public.status        CASCADE;
DROP TABLE IF EXISTS public.region        CASCADE;
DROP TABLE IF EXISTS public.organismtype  CASCADE;


-- ─────────────────────────────────────────────────────────────
-- 1. ORGANISMTYPE  (lookup — animal classification)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.organismtype (
    organismtypeid      INTEGER      NOT NULL,
    type                VARCHAR(100),
    organismdescription VARCHAR(300),
    CONSTRAINT organismtype_pkey PRIMARY KEY (organismtypeid)
);

INSERT INTO public.organismtype (organismtypeid, type, organismdescription) VALUES
(1, 'Mammal',    'Warm-blooded vertebrates with fur or hair; give birth to live young'),
(2, 'Bird',      'Warm-blooded vertebrates with feathers and beaks; most can fly'),
(3, 'Reptile',   'Cold-blooded vertebrates with scales; includes snakes, lizards, turtles, caimans'),
(4, 'Amphibian', 'Cold-blooded vertebrates that live in both water and on land; includes frogs and salamanders');


-- ─────────────────────────────────────────────────────────────
-- 2. STATUS  (lookup — IUCN conservation status)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.status (
    statusid    INTEGER      NOT NULL,
    statusvalue VARCHAR(200),
    risklevel   INTEGER,   -- 1 = most endangered; 5 = least concern; 0 = extinct
    CONSTRAINT status_pkey PRIMARY KEY (statusid)
);

INSERT INTO public.status (statusid, statusvalue, risklevel) VALUES
(1, 'Critically Endangered', 1),
(2, 'Endangered',            2),
(3, 'Vulnerable',            3),
(4, 'Near Threatened',       4),
(5, 'Least Concern',         5),
(6, 'Extinct',               0);


-- ─────────────────────────────────────────────────────────────
-- 3. REGION  (lookup — Amazon sub-regions)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.region (
    regionid   INTEGER      NOT NULL,
    regionname VARCHAR(200),
    ecosystem  VARCHAR(200),
    CONSTRAINT region_pkey PRIMARY KEY (regionid)
);

INSERT INTO public.region (regionid, regionname, ecosystem) VALUES
(1, 'Brazilian Amazon',   'Tropical rainforest, cerrado, and pantanal wetlands'),
(2, 'Peruvian Amazon',    'Cloud forest, tropical lowland rainforest, and Andean foothills'),
(3, 'Colombian Amazon',   'Tropical rainforest and flooded várzea forest'),
(4, 'Ecuadorian Amazon',  'Tropical rainforest with high biodiversity and cloud forest'),
(5, 'Bolivian Amazon',    'Tropical lowland rainforest and seasonally flooded savanna');


-- ─────────────────────────────────────────────────────────────
-- 4. THREAT  (lookup — environmental threat categories)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.threat (
    threatid  INTEGER      NOT NULL,
    threatname VARCHAR(200),
    CONSTRAINT threat_pkey PRIMARY KEY (threatid)
);

INSERT INTO public.threat (threatid, threatname) VALUES
(1, 'Deforestation'),
(2, 'Poaching & Illegal Trade'),
(3, 'Agricultural Expansion'),
(4, 'Mining & Pollution'),
(5, 'Climate Change');


-- ─────────────────────────────────────────────────────────────
-- 5. SPECIES  (core table)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.species (
    speciesid      INTEGER      NOT NULL,
    commonname     VARCHAR(200),
    scientificname VARCHAR(200),
    organismtypeid INTEGER,
    statusid       INTEGER,
    regionid       INTEGER,
    habitat        VARCHAR(200),
    CONSTRAINT species_pkey             PRIMARY KEY (speciesid),
    CONSTRAINT species_organismtypeid_fkey FOREIGN KEY (organismtypeid) REFERENCES public.organismtype(organismtypeid),
    CONSTRAINT species_statusid_fkey       FOREIGN KEY (statusid)       REFERENCES public.status(statusid),
    CONSTRAINT species_regionid_fkey       FOREIGN KEY (regionid)       REFERENCES public.region(regionid)
);

-- ── Threatened Mammals ───────────────────────────────────────
INSERT INTO public.species (speciesid, commonname, scientificname, organismtypeid, statusid, regionid, habitat) VALUES
(1,  'Amazon River Dolphin',        'Inia geoffrensis',                1, 3, 1, 'Rivers and flooded forests'),
(2,  'Jaguar',                       'Panthera onca',                   1, 3, 1, 'Tropical rainforest and wetlands'),
(3,  'Giant Otter',                  'Pteronura brasiliensis',          1, 2, 1, 'Rivers, lakes and swamps'),
(4,  'Giant Anteater',               'Myrmecophaga tridactyla',         1, 3, 5, 'Grassland and forest edge'),
(8,  'South American Tapir',         'Tapirus terrestris',              1, 3, 3, 'Tropical forest and riverbanks'),
(11, 'Pygmy Sloth',                  'Bradypus pygmaeus',               1, 1, 3, 'Mangrove forest canopy'),
(12, 'White-Cheeked Spider Monkey',  'Ateles marginatus',               1, 2, 1, 'Tropical rainforest canopy');

-- ── Threatened Birds ─────────────────────────────────────────
INSERT INTO public.species (speciesid, commonname, scientificname, organismtypeid, statusid, regionid, habitat) VALUES
(5,  'Harpy Eagle',             'Harpia harpyja',              2, 4, 2, 'Rainforest canopy'),
(6,  'Spix''s Macaw',           'Cyanopsitta spixii',          2, 1, 1, 'Caatinga woodland'),
(13, 'Hyacinth Macaw',          'Anodorhynchus hyacinthinus',  2, 3, 1, 'Open woodland and palm groves'),
(40, 'Scarlet Macaw',           'Ara macao',                   2, 3, 2, 'Tropical forest and woodland'),
(41, 'Amazonian Umbrella Bird', 'Cephalopterus ornatus',       2, 4, 3, 'Lowland tropical rainforest');

-- ── Threatened Reptiles ──────────────────────────────────────
INSERT INTO public.species (speciesid, commonname, scientificname, organismtypeid, statusid, regionid, habitat) VALUES
(7,  'Black Caiman',                  'Melanosuchus niger',    3, 5, 1, 'Slow rivers, lakes and flooded forest'),
(10, 'Yellow-spotted Amazon Turtle',  'Podocnemis unifilis',   3, 3, 2, 'Rivers and flooded forests'),
(42, 'Amazon River Turtle',           'Podocnemis expansa',    3, 3, 1, 'Large rivers and sandbars'),
(43, 'Green Anaconda',                'Eunectes murinus',      3, 4, 1, 'Swamps, marshes and slow rivers'),
(44, 'Matamata Turtle',               'Chelus fimbriata',      3, 4, 2, 'Slow-moving blackwater streams');

-- ── Threatened Amphibians ────────────────────────────────────
INSERT INTO public.species (speciesid, commonname, scientificname, organismtypeid, statusid, regionid, habitat) VALUES
(9,  'Poison Dart Frog',       'Dendrobates tinctorius',       4, 5, 4, 'Humid tropical forest floor'),
(45, 'Amazon Milk Frog',       'Trachycephalus resinifictrix', 4, 4, 1, 'Forest canopy near water'),
(47, 'Phantasmal Poison Frog', 'Epipedobates tricolor',        4, 2, 4, 'Cloud forest streams');

-- ── Extinct Mammals ──────────────────────────────────────────
INSERT INTO public.species (speciesid, commonname, scientificname, organismtypeid, statusid, regionid, habitat) VALUES
(20, 'Amazonian Wolf',              'Speothos venaticus amazonicus',    1, 6, 1, 'Tropical forest and savanna'),
(21, 'Caribbean Monk Seal',         'Neomonachus tropicalis',           1, 6, 1, 'Coastal waters and beaches'),
(22, 'Lesser Amazonian Manatee',    'Trichechus inunguis minor',        1, 6, 2, 'Slow rivers and coastal lagoons'),
(23, 'Giant Amazon Peccary',        'Pecari maximus',                   1, 6, 1, 'Dense rainforest'),
(24, 'Amazonian Tapir Subspecies',  'Tapirus terrestris aenigmaticus',  1, 6, 3, 'Colombian lowland rainforest');

-- ── Extinct Birds ────────────────────────────────────────────
INSERT INTO public.species (speciesid, commonname, scientificname, organismtypeid, statusid, regionid, habitat) VALUES
(25, 'Glaucous Macaw',      'Anodorhynchus glaucus',   2, 6, 1, 'Riverine palm groves'),
(26, 'Alagoas Curassow',    'Mitu mitu',               2, 6, 1, 'Atlantic forest fragments'),
(27, 'Spix''s Macaw (Wild)','Cyanopsitta spixii',      2, 6, 1, 'Caatinga gallery forest'),
(28, 'Pooo-uli',            'Melamprosops phaeosoma',  2, 6, 4, 'Cloud forest understory'),
(29, 'Bogota Sunangel',     'Heliangelus zusii',       2, 6, 3, 'Cloud forest');

-- ── Extinct Reptiles ─────────────────────────────────────────
INSERT INTO public.species (speciesid, commonname, scientificname, organismtypeid, statusid, regionid, habitat) VALUES
(30, 'Rodrigues Giant Tortoise', 'Cylindraspis vosmaeri',     3, 6, 1, 'Dry island scrubland'),
(31, 'Amazon River Crocodilian', 'Gryposuchus colombianus',   3, 6, 3, 'Large Amazonian rivers'),
(32, 'Ecuadorian Dwarf Gecko',   'Lepidoblepharis buchwaldi', 3, 6, 4, 'Tropical forest floor'),
(33, 'Martinique Galliwasp',     'Celestus occiduus',         3, 6, 1, 'Moist tropical forest'),
(34, 'Fernandina Racer',         'Alsophis ater',             3, 6, 2, 'Island scrub vegetation');

-- ── Extinct Amphibians ───────────────────────────────────────
INSERT INTO public.species (speciesid, commonname, scientificname, organismtypeid, statusid, regionid, habitat) VALUES
(35, 'Golden Toad',          'Incilius periglenes',  4, 6, 3, 'Cloud forest pools'),
(36, 'Gastric Brooding Frog','Rheobatrachus silus',  4, 6, 1, 'Rainforest streams');


-- ─────────────────────────────────────────────────────────────
-- 6. SPECIESTHREATS  (junction — many-to-many)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE public.speciesthreats (
    speciesid INTEGER NOT NULL,
    threatid  INTEGER NOT NULL,
    CONSTRAINT speciesthreats_pkey        PRIMARY KEY (speciesid, threatid),
    CONSTRAINT speciesthreats_speciesid_fkey FOREIGN KEY (speciesid) REFERENCES public.species(speciesid),
    CONSTRAINT speciesthreats_threatid_fkey  FOREIGN KEY (threatid)  REFERENCES public.threat(threatid)
);

-- Species → Threat links (based on Excel dataset)
INSERT INTO public.speciesthreats (speciesid, threatid) VALUES
-- Amazon River Dolphin: Deforestation, Mining & Pollution
(1, 1), (1, 4),
-- Jaguar: Deforestation, Poaching, Agricultural Expansion
(2, 1), (2, 2), (2, 3),
-- Giant Otter: Deforestation, Mining & Pollution, Poaching
(3, 1), (3, 4), (3, 2),
-- Giant Anteater: Deforestation, Agricultural Expansion
(4, 1), (4, 3),
-- South American Tapir: Deforestation, Climate Change
(8, 1), (8, 5),
-- Pygmy Sloth: Deforestation, Climate Change
(11, 1), (11, 5),
-- White-Cheeked Spider Monkey: Deforestation, Agricultural Expansion, Poaching
(12, 1), (12, 3), (12, 2),
-- Harpy Eagle: Deforestation, Poaching
(5, 1), (5, 2),
-- Spix's Macaw: Deforestation, Poaching
(6, 1), (6, 2),
-- Hyacinth Macaw: Deforestation, Poaching
(13, 1), (13, 2),
-- Scarlet Macaw: Deforestation, Poaching
(40, 1), (40, 2),
-- Amazonian Umbrella Bird: Deforestation, Agricultural Expansion
(41, 1), (41, 3),
-- Yellow-spotted Amazon Turtle: Poaching, Agricultural Expansion
(10, 2), (10, 3),
-- Amazon River Turtle: Poaching, Agricultural Expansion
(42, 2), (42, 3),
-- Green Anaconda: Deforestation, Poaching
(43, 1), (43, 2),
-- Matamata Turtle: Mining & Pollution, Poaching
(44, 4), (44, 2),
-- Amazon Milk Frog: Deforestation, Poaching
(45, 1), (45, 2),
-- Phantasmal Poison Frog: Deforestation, Climate Change
(47, 1), (47, 5);


-- ─────────────────────────────────────────────────────────────
-- Verification queries — run these to confirm data loaded
-- ─────────────────────────────────────────────────────────────

-- SELECT count(*) FROM species;          -- should be 37
-- SELECT count(*) FROM speciesthreats;   -- should be 36

-- Full species list with joined names:
-- SELECT s.speciesid, s.commonname, s.scientificname,
--        o.type, st.statusvalue, r.regionname
-- FROM species s
-- JOIN organismtype o ON s.organismtypeid = o.organismtypeid
-- JOIN status st      ON s.statusid = st.statusid
-- JOIN region r       ON s.regionid = r.regionid
-- ORDER BY st.risklevel ASC, s.commonname;
