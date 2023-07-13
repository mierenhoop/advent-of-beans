DB_FILE ="/tmp/out.db"
COOKIE_KEY="advent_session"

local _db
db = {}

local function prep(sql, ...)
  local stmt = _db:prepare(sql)
  if not stmt then error(_db:errmsg()) end
  assert(stmt:bind_values(...) == lsqlite3.OK)
  return stmt
end

function db.exec(sql)
  local ret = _db:exec(sql)
  if ret ~= lsqlite3.OK then error(_db:errmsg()) end
end

function db.urow(sql, ...)
  local stmt = prep(sql, ...)
  local rows = table.pack(stmt:urows()(stmt))
  stmt:finalize()
  return table.unpack(rows)
end

function db.urows(sql, ...)
  local stmt = prep(sql, ...)
  local closer = setmetatable({}, {
    __close = function() stmt:finalize() end
  })
  return stmt:urows(), stmt, nil, closer
end

function db.transaction(f)
  db.exec"BEGIN TRANSACTION;"

  local ok, err = pcall(f)
  if not ok then
    db.exec"ROLLBACK;"
    error(err)
  end

  db.exec"COMMIT;"
end

local curtoken, curuser
function db.get_session_user_id() -- simply cached
  local token = GetCookie(COOKIE_KEY)
  if not token then return nil end
  if token == curtoken then return curuser end
  curtoken, curuser = token, db.urow("SELECT user_id FROM session WHERE token = ?", token)
  return curuser
end

local function fill_bucket(puzzle, amount)
  local code = db.urow([[
  SELECT gen_code FROM puzzle WHERE name = ?
  ]], puzzle)
  local f = assert(load(code))

  local entropy = os.time()

  for i = 1, amount do
    math.randomseed(entropy+i)
    local input, silver, gold = f()
    assert(input and silver)
    db.urow([[
    INSERT INTO bucket(puzzle, input, silver_answer, gold_answer) VALUES (?, ?, ?, ?)
    ]], puzzle, input, silver, gold)
  end
end

function db.get_user_bucket(user_id, puzzle)
  local bucket = db.urow([[
  SELECT bucket_id
  FROM user_puzzle
  WHERE puzzle = ?
    AND user_id = ?
  ]], puzzle, user_id)

  if not bucket then
    --TODO: instead of random bucket, maybe ring loop index over bucket
    ::randombucket::
    bucket = db.urow([[
    SELECT rowid
    FROM bucket
    WHERE puzzle = ?
    ORDER BY RANDOM()
    LIMIT 1;
    ]], puzzle)
    if not bucket then
      fill_bucket(puzzle, 10)
      goto randombucket
    end
    db.urow([[
    INSERT INTO user_puzzle(user_id, puzzle, bucket_id)
    VALUES (?, ?, ?)
    ]], user_id, puzzle, bucket)
  end
  return bucket
end

local function open_db()
  _db = lsqlite3.open(DB_FILE)
  _db:busy_timeout(1000)
  db.exec[[
  PRAGMA journal_mode=wal;
  PRAGMA synchronous=normal;
  ]]
end

function OnWorkerStart()
  open_db()
end

function OnServerHeartbeat()
  --TODO: probably horribly inefficient
  --TODO: fork here? permissions?
  open_db()
  db.transaction(function()
    local users = {}
    db.exec[[DELETE FROM leaderboard]]
    for name in db.urows[[
      SELECT name
      FROM puzzle
      ]] do
      local score = 100
      for user_id in db.urows([[
        SELECT user_id
        FROM user_puzzle
        WHERE puzzle = ?
        AND silver_time IS NOT NULL
        ORDER BY silver_time
        LIMIT 100
        ]], name) do
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
  _db:close()
end

ProgramHeartbeatInterval(3 * 1000) -- 10s

wrt, fmt, esc = Write, string.format, EscapeHtml

html = {}

function html.page_begin(title)
  wrt[[<!DOCTYPE html>]]
  wrt[[<html lang="en">]]
  wrt[[<meta charset="UTF-8">]]
  wrt[[<link rel="stylesheet" href="/style.css">]]
  wrt[[<nav>]]
  wrt[[<a href="/">Advent</a>]]
  wrt" | "
  wrt[[<a href="/about">About</a>]]
  wrt" | "
  wrt[[<a href="/leaderboard">Leaderboard</a>]]
  wrt" | "
  local user_id = db.get_session_user_id()
  local name
  if user_id then
    name = db.urow("SELECT name FROM user WHERE rowid = ?", user_id)
  end
  wrt(fmt([[<a href="/profile">%s</a>]], name and EscapeHtml(name) or "Login"))

  --html.maybelink("Leaderboard", p ~= "/leaderboard.lua" and "/leaderboard.lua")
  wrt[[</nav>]]
  wrt"<main>"
end

function html.page_end()
  wrt"</main>"
  wrt[[</html>]]
end

function html.leaderboard_begin()
  html.page_begin()

  wrt"<p>Per day:"
  for name in db.urows"SELECT name FROM puzzle ORDER BY time_start" do
    local link = name
    if name == puzzle then name = "<strong>"..name.."</strong>" end
    wrt(fmt([[ <a href="/%s/leaderboard">%s</a>]], link, name))
  end
  wrt"</p>"
end

function OnHttpRequest()
  local p = GetPath()

  if p == "/style.css" then return ServeAsset("/style.css") end

  local cmd

  puzzle, cmd = p:match"^/(%d%d?)/?(%l*)$"
  if not cmd then cmd = p:match"^/(%l*)$" end
  if not cmd then return ServeError(404) end
  if cmd == "" then cmd = "index" end
  if puzzle then cmd = "puzzle-" .. cmd end

  --print("Access", "/"..cmd..".lua")

  return RoutePath("/"..cmd..".lua")
end

