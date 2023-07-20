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
  fail_msg    TEXT,
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
  user_id INTEGER UNIQUE NOT NULL,
  score   INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS avatar_cache (
  user_id      INTEGER NOT NULL UNIQUE,
  body         TEXT NOT NULL,
  content_type TEXT NOT NULL
);
