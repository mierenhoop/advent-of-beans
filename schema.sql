-- TODO: is this needed here?
PRAGMA journal_mode=wal;
PRAGMA synchronous=normal;

CREATE TABLE IF NOT EXISTS user (
  name  TEXT NOT NULL,
  link  TEXT
  --score INTEGER NOT NULL DEFAULT 0,
);

CREATE TABLE IF NOT EXISTS session (
  user_id INTEGER NOT NULL UNIQUE,
  token   TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS achievement (
  user_id   INTEGER NOT NULL,
  puzzle    TEXT NOT NULL,
  time      INTEGER NOT NULL, -- unix time
  type      TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS puzzle (
  name       TEXT NOT NULL UNIQUE,
  time_start REAL NOT NULL, -- unix time
  part1      TEXT NOT NULL,
  part2      TEXT NOT NULL,
  gen_code   TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS user_puzzle(
  user_id     INTEGER NOT NULL,
  puzzle      TEXT NOT NULL,
  bucket_id   INTEGER NOT NULL,
  last_try    INTEGER, -- unix time
  next_try    INTEGER, -- unix time maybe we don't need the previous
  silver_time REAL,
  gold_time   REAL,
  fails       INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS bucket(
  puzzle        TEXT NOT NULL,
  input         BLOB NOT NULL,
  silver_answer BLOB NOT NULL,
  gold_answer   BLOB NOT NULL
);

CREATE TABLE IF NOT EXISTS leaderboard (
  score   INTEGER NOT NULL DEFAULT 0,
  user_id INTEGER NOT NULL
);

INSERT INTO user(name, link) VALUES ('Joe1', 'https://github.com/joe1'),
('Joe2', NULL), ('Joe3', 'https://github.com/joe3'),
('Joe4', NULL), ('Joe5', 'https://github.com/joe5'),
('Joe6', NULL), ('Joe7', 'https://github.com/joe7'),
('Joe8', NULL), ('Joe9', 'https://github.com/joe9'),
('Joe10', NULL), ('Joe11', 'https://github.com/joe11'),
('Joe12', NULL), ('Joe13', 'https://github.com/joe13'),
('Joe14', NULL), ('Joe15', 'https://github.com/joe15'),
('Joe16', NULL), ('Joe17', 'https://github.com/joe17'),
('Joe18', NULL), ('Joe19', 'https://github.com/joe19'),
('Joe20', NULL), ('Joe21', 'https://github.com/joe21'),
('Joe22', NULL), ('Joe23', 'https://github.com/joe23'),
('Joe24', NULL), ('Joe25', 'https://github.com/joe25'),
('Joe26', NULL), ('Joe27', 'https://github.com/joe27'),
('Joe28', NULL), ('Joe29', 'https://github.com/joe29'),
('Joe30', NULL);


INSERT INTO puzzle (name, time_start, part1, part2, gen_code) VALUES (
  '01', UNIXEPOCH(), '
<p>Add one to input</p>
<em>Example:</em>
<pre>
9
</pre>
<p>The answer would be <code>10</code>.</p>','
<p>Add two to input</p>
<p>With the same input as before, the answer would be <code>10</code>.</p>', '
  local n = math.random(998)
  return n, n + 1, n + 2
'), (
  '02', UNIXEPOCH()+10, '
<p>Multiply by four</p>
<em>Example:</em>
<pre>
9
</pre>
<p>The answer would be <code>36</code>.</p>','
<p>Multiply by 5</p>
<p>With the same input as before, the answer would be <code>45</code>.</p>', '
  local n = math.random(100, 249)
  return n, n * 4, n * 5')
