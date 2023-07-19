-- TODO: is this needed here?
PRAGMA journal_mode=wal;
PRAGMA synchronous=normal;

CREATE TABLE IF NOT EXISTS user (
  name      TEXT NOT NULL,
  link      TEXT,
  gh_id     INTEGER NOT NULL,
  gh_auth   TEXT NOT NULL,
  anonymous INTEGER NOT NULL DEFAULT TRUE -- 0 -> false, 1 -> true
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
  time_start INTEGER NOT NULL, -- unix time
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

CREATE TABLE IF NOT EXISTS avatar_cache (
  user_id      INTEGER NOT NULL UNIQUE,
  body         TEXT NOT NULL,
  content_type TEXT NOT NULL
);

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
