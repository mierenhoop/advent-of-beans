--package.path=package.path..";./.lua/?.lua"

--local def = {}
--for k in pairs(package.loaded) do def[k] = true end
--
--function OnHttpRequest()
--  -- clear package cache
--  for k in pairs(package.loaded) do
--    if not def[k] then package.loaded[k] = nil end
--  end
--  Route()
--end
DB_FILE ="/tmp/out.db"
COOKIE_KEY="advent_session"

os.remove(DB_FILE)
os.remove(DB_FILE.."-wal")
os.remove(DB_FILE.."-shm")


local db = require "db"

--TODO: db is locked whenever not using wal mode
-- probably bad optimization, keeping db handles and or
-- statement handles around while not needed
-- TODO: use rowid instead of id autoincrement
db.exec [[
PRAGMA journal_mode=wal;
PRAGMA synchronous=normal;

CREATE TABLE IF NOT EXISTS user (
  id    INTEGER NOT NULL UNIQUE DEFAULT 0,
  name  TEXT NOT NULL,
  link  TEXT,
  --score INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (id AUTOINCREMENT)
);

CREATE TABLE IF NOT EXISTS session (
  user_id INTEGER NOT NULL UNIQUE,
  token TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS achievement (
  user_id   INTEGER NOT NULL,
  puzzle_id INTEGER NOT NULL,
  time      INTEGER NOT NULL, -- unix time
  type      TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS puzzle (
  id   INTEGER NOT NULL UNIQUE DEFAULT 0,
  name TEXT NOT NULL UNIQUE,
  time_start REAL NOT NULL, -- unix time
  html TEXT NOT NULL,
  gen_code TEXT NOT NULL,
  PRIMARY KEY (id AUTOINCREMENT)
);

CREATE TABLE IF NOT EXISTS user_puzzle(
  user_id   INTEGER NOT NULL,
  puzzle_id INTEGER NOT NULL,
  bucket_id INTEGER NOT NULL,
  last_try INTEGER, -- unix time
  next_try INTEGER, -- unix time maybe we don't need the previous
  silver_time REAL,
  gold_time REAL,
  fails INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS bucket(
  id INTEGER NOT NULL UNIQUE DEFAULT 0,
  puzzle_id INTEGER NOT NULL,
  input     BLOB NOT NULL,
  silver_answer    BLOB NOT NULL,
  gold_answer,
  PRIMARY KEY (id AUTOINCREMENT)
);

CREATE TABLE IF NOT EXISTS leaderboard (
  score INTEGER NOT NULL DEFAULT 0,
  user_id INTEGER NOT NULL
);

--CREATE TRIGGER IF NOT EXISTS update_score
--  AFTER INSERT
--  ON achievement
--BEGIN
--  UPDATE user SET score = score + 1 WHERE id = NEW.user_id;
--END;
]]

for i=1,30 do
  local link
  local name = "Joe" .. i
  if i % 2 == 0 then
    link = "https://github.com/" .. name
  end
  db.urow("INSERT INTO user(name, link) VALUES (?, ?)", name, link)
end

db.urow([[
INSERT INTO puzzle (name, time_start, html, gen_code) VALUES (
  '01', ?, '
<p>Add one to input</p>
<em>Example:</em>
<pre>
9
</pre>
<p>The answer would be <code>10</code>.</p>
$PART2$
<p>Add two to input</p>
<p>With the same input as before, the answer would be <code>10</code>.</p>
  ', '
  local n = math.random(998)
  return n, n + 1, n + 2
'), (
  '02', ?, '
<p>Multiply by four</p>
<em>Example:</em>
<pre>
9
</pre>
<p>The answer would be <code>36</code>.</p>
$PART2$
<p>Multiply by 5</p>
<p>With the same input as before, the answer would be <code>45</code>.</p>
  ', '
  local n = math.random(100, 249)
  return n, n * 4, n * 5
');]], GetTime(), GetTime() + 10)


package.loaded.db = nil -- MAKE SURE WORKERS DON'T HAVE DB HANDLE FROM HERE
db = nil
collectgarbage()

function OnServerHeartbeat()
  db = require"db"

  --TODO: probably horribly inefficient
  db.transaction(function()
    local users = {}
    db.exec[[DELETE FROM leaderboard]]
    for puzzle_id in db.urows[[
      SELECT id
      FROM puzzle
      ]] do
      local score = 100
      for user_id in db.urows([[
        SELECT user_id
        FROM user_puzzle
        WHERE puzzle_id = ?
        AND silver_time IS NOT NULL
        ORDER BY silver_time
        LIMIT 100
        ]], puzzle_id) do
        users[user_id]=(users[user_id] or 0) + score
        score=score-1
      end
    end
    -- TODO: avoid this loop, add the score to leaderboard in loop above
    for user_id, score in pairs(users) do
      db.urow([[
      INSERT INTO leaderboard(user_id, score) VALUES (?, ?)
      ]], user_id, score)
    end
  end)
end

ProgramHeartbeatInterval(10 * 1000) -- 10s
