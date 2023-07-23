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
  gen_code   TEXT NOT NULL,

  silver_size INTEGER NOT NULL DEFAULT 0,
  gold_size INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_puzzle(
  user_id     INTEGER NOT NULL,
  puzzle      TEXT NOT NULL,
  bucket_id   INTEGER NOT NULL,
  silver_time INTEGER,
  gold_time   INTEGER
);

CREATE TABLE IF NOT EXISTS bucket(
  puzzle        TEXT NOT NULL,
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
  (100+1-row_number() OVER (PARTITION BY puzzle ORDER BY silver_time, user_id)) AS silver_score
  FROM user_puzzle
  WHERE silver_time IS NOT NULL
)
INNER JOIN user ON user.rowid = user_id
GROUP BY user_id;

CREATE VIEW IF NOT EXISTS all_gold AS
SELECT user_id, SUM(gold_score) AS score
FROM (
  SELECT user_id,
  (100+1-row_number() OVER (PARTITION BY puzzle ORDER BY gold_time, user_id)) AS gold_score
  FROM user_puzzle
  WHERE gold_time IS NOT NULL
)
INNER JOIN user ON user.rowid = user_id
GROUP BY user_id;

CREATE TABLE IF NOT EXISTS avatar_cache (
  user_id      INTEGER NOT NULL UNIQUE,
  body         TEXT NOT NULL,
  content_type TEXT NOT NULL
);
