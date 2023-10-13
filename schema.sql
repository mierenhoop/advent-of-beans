-- vim: et sw=2 sts=2

CREATE TABLE IF NOT EXISTS user (
  name      TEXT NOT NULL,
  link      TEXT,
  gh_id     INTEGER NOT NULL,
  gh_auth   TEXT NOT NULL,
  anonymous INTEGER NOT NULL DEFAULT TRUE, -- 0 -> false, 1 -> true

  next_try    INTEGER,
  fails       INTEGER
);

CREATE TABLE IF NOT EXISTS session (
  user_id INTEGER NOT NULL UNIQUE,
  token   TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS event (
  name    TEXT NOT NULL UNIQUE,
  time    INTEGER NOT NULL -- unix time
);

CREATE TABLE IF NOT EXISTS achievement (
  user_id   INTEGER NOT NULL,
  puzzle_id INTEGER NOT NULL,
  time      INTEGER NOT NULL, -- unix time
  type      TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS puzzle (
  name       TEXT NOT NULL UNIQUE,
  event_id   INTEGER NOT NULL,
  time_start INTEGER NOT NULL, -- unix time
  part1      TEXT NOT NULL,
  part2      TEXT NOT NULL,
  gen_code   TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS user_puzzle(
  user_id     INTEGER NOT NULL,
  puzzle_id   INTEGER NOT NULL,
  bucket_id   INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS bucket(
  puzzle_id     integer NOT NULL,
  input         TEXT NOT NULL,
  silver_answer BLOB NOT NULL,
  gold_answer   BLOB NOT NULL
);

CREATE TABLE IF NOT EXISTS leaderboard (
  user_id INTEGER UNIQUE NOT NULL,
  score   INTEGER NOT NULL DEFAULT 0
);

CREATE VIEW IF NOT EXISTS all_silver AS
SELECT user_id, SUM(silver_score) AS score
FROM (
  SELECT user_id,
  (100+1-row_number() OVER (PARTITION BY puzzle_id ORDER BY time, rowid)) AS silver_score
  FROM achievement
  WHERE type = 'silver'
)
INNER JOIN user ON user.rowid = user_id
GROUP BY user_id;

CREATE VIEW IF NOT EXISTS all_gold AS
SELECT user_id, SUM(gold_score) AS score
FROM (
  SELECT user_id,
  (100+1-row_number() OVER (PARTITION BY puzzle_id ORDER BY time, rowid)) AS gold_score
  FROM achievement
  WHERE type = 'gold'
)
INNER JOIN user ON user.rowid = user_id
GROUP BY user_id;

CREATE TABLE IF NOT EXISTS avatar_cache (
  user_id      INTEGER NOT NULL UNIQUE,
  body         TEXT NOT NULL,
  content_type TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS write_limiter (
  user_id INTEGER NOT NULL UNIQUE,
  writes  INTEGER DEFAULT 0
);
