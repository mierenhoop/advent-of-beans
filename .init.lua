local exe = arg[-1]
local exedir = path.dirname(exe)

local defaultdb = path.join(exedir, "aob.db")
local DB_FILE = os.getenv"AOB_DB_FILE" or defaultdb

config = {}
config.LEADERBOARD_INTERVAL = 3
config.BUCKET_AMOUNT=1000

local MAX_WRITES=10

db = {}
db.cookie_key = "advent_session"
db.cookie_answer = "advent_answer"
html = {}
github = {}
github.client_id = assert(os.getenv"AOB_GH_CLIENT_ID")
github.client_secret = assert(os.getenv"AOB_GH_CLIENT_SECRET")

function db.open()
  local pid = unix.getpid()
  assert(db.curpid ~= pid, "db: already open in current process")

  db._db = assert(lsqlite3.open(DB_FILE), "db: could not open")
  db.curpid = pid
  Log(kLogInfo, "db: open, pid: " .. pid)

  db._db:busy_timeout(1000)
  return setmetatable({}, {
    __close = function()
      db.close()
    end
  })
end

function db.close()
  Log(kLogInfo, "db: closed, pid: " .. db.curpid)
  db._db:close()
  db._db = nil
  db.curpid = nil
end

local function dbok(ret)
  if ret ~= lsqlite3.OK then
    error(db._db:errmsg())
  end
end

local function prep(sql, ...)
  local stmt = db._db:prepare(sql)
  if not stmt then error(db._db:errmsg()) end
  dbok(stmt:bind_values(...))
  return stmt
end


function db.exec(sql)
  dbok(db._db:exec(sql))
end

function db.urow(sql, ...)
  local iter, state, _, closer <close> = db.urows(sql, ...)
  return iter(state)
end

function db.urows(sql, ...)
  local stmt = prep(sql, ...)
  local closer = setmetatable({}, {
    __close = function()
      dbok(stmt:finalize())
    end
  })
  return stmt:urows(), stmt, nil, closer
end

local intrans = false
function db.transaction(f)
  if intrans then return f() end

  db.exec"BEGIN TRANSACTION;"

  intrans = true
  local ok, err = pcall(f)
  intrans = false
  if not ok then
    db.exec"ROLLBACK;"
    error(err)
  end

  db.exec"COMMIT;"
end

local curtoken, curuser
function db.get_session_user_id() -- simply cached
  local token = GetCookie(db.cookie_key)
  if not token then return nil end
  if token == curtoken then return curuser end
  curtoken, curuser = token, db.urow("SELECT user_id FROM session WHERE token = ?", token)
  return curuser
end

local function fill_bucket(puzzle_id, amount)
  local code = db.urow([[
  SELECT gen_code FROM puzzle WHERE rowid = ?
  ]], puzzle_id)
  local f = assert(load(code))

  local entropy = os.time()

  db.transaction(function()
    for i = 1, amount do
      math.randomseed(entropy+i)
      local input, silver, gold = f()
      assert(input and silver)
      db.urow([[
      INSERT INTO bucket(puzzle_id, input, silver_answer, gold_answer) VALUES (?, ?, ?, ?)
      ]], puzzle_id, input, silver, gold)
    end
  end)
end

function db.get_user_bucket(user_id, puzzle_id)
  local bucket = db.urow([[
  SELECT bucket_id
  FROM user_puzzle
  WHERE puzzle_id = ?
  AND user_id = ?
  ]], puzzle_id, user_id)

  if not bucket then
    --TODO: instead of random bucket, maybe ring loop index over bucket
    ::randombucket::
    bucket = db.urow([[
    SELECT rowid
    FROM bucket
    WHERE puzzle_id = ?
    ORDER BY RANDOM()
    LIMIT 1;
    ]], puzzle_id)
    assert(bucket)
    db.urow([[
    INSERT INTO user_puzzle(user_id, puzzle_id, bucket_id)
    VALUES (?, ?, ?)
    ]], user_id, puzzle_id, bucket)
  end
  return bucket
end

function db.write_limiter()
  db.urow([[
  INSERT OR IGNORE INTO write_limiter(user_id) VALUES (?);
  ]], db.user_id)
  local writes = db.urow([[
  SELECT writes FROM write_limiter WHERE user_id = ?
  ]], db.user_id)
  if writes > MAX_WRITES then
    ServeError(429)
    SetHeader('Connection', 'close')
    return true
  end
  db.urow([[
  UPDATE write_limiter SET writes = writes + 1 WHERE user_id = ?
  ]], db.user_id)
end

--local function htmlformat(fmt, ...)
--  local index = 1
--  return string.gsub(fmt, "%%[es]", function(v)
--    local s = tostring(select(index, ...))
--    index = index + 1
--    return v == "%e" and EscapeHtml(s) or s
--  end)
--end

setmetatable(html, {
  __call = function(_, ...)
    -- TODO: have specific feature for escaped html...
    Write(string.format(...))
  end
})

function html.page_begin(title)
  html[[<!DOCTYPE html>]]
  html[[<html lang="en">]]
  html[[<meta charset="UTF-8">]]
  html[[<link rel="stylesheet" href="/style.css">]]
  html[[<nav>]]
  html[[<a href="/">Advent</a> | ]]
  html([[<a href="%s">About</a> | ]], EscapeHtml(html.link"about"))
  html([[<a href="%s">Events</a> | ]], EscapeHtml(html.link"events"))
  html([[<a href="%s">Leaderboard</a> | ]], EscapeHtml(html.link"leaderboard"))
  html([[<a href="%s">Stats</a> | ]], EscapeHtml(html.link"stats"))
  local name
  if db.user_id then
    name = db.urow("SELECT name FROM user WHERE rowid = ?", db.user_id)
  end
  html([[<a href="%s">%s</a>]], EscapeHtml(html.link"profile"), name and EscapeHtml(name) or "Login")

  --html.maybelink("Leaderboard", p ~= "/leaderboard.lua" and "/leaderboard.lua")
  html[[</nav>]]
  html[[<main>]]
end

function html.page_end()
  html[[</main>]]
  html[[</html>]]
end

function html.leaderboard_begin()
  html.page_begin()

  html[[<p>Per day:]]
  for id, name in db.urows"SELECT rowid, name FROM puzzle ORDER BY time_start" do
    local link = name
    name = EscapeHtml(name)
    if id == db.puzzle_id then name = "<strong>"..name.."</strong>" end
    html([[ <a href="%s">%s</a>]],
    EscapeHtml(html.linkpuzzle("leaderboard", link)), name)
  end
  html[[</p>]]
end

function html.user(user_id, anon, name, link)
  --TODO: lazy load avatar
  if anon then
    html("Anonymous #" .. tostring(user_id))
    return
  end

  html([[<img src="/avatar-%d" height="20">]], user_id)

  name = EscapeHtml(name)
  local host = link and ParseUrl(link).host
  if link and host then
    html([[<a href="%s">%s</a><sub>[%s]</sub>]],
    EscapeHtml(link), name, EscapeHtml(host))
  else
    html(name)
  end
end

local current_event = "2023"

function html.linkpuzzle(path, puzzle_name, event_name)
  local ret = "/"..EscapeSegment(event_name or db.event_name)
  .."/day/"..EscapeSegment(puzzle_name or db.puzzle_name)
  if path then
    return ret.."/"..path
  end
  return ret
end

function html.link(path, event_name)
  local link = "/"..EscapeSegment(event_name or db.event_name)
  if path then
    return link.."/"..path
  end
  return link
end

function github.fetch_user(gh_auth)
  local opts = {
    method = "GET",
    headers = {
      ["Accept"] = "application/vnd.github+json",
      ["Authorization"] = "Bearer " .. gh_auth,
      ["X-GitHub-Api-Version"] = "2022-11-28",
    },
  }
  local stat, _, body = assert(Fetch("https://api.github.com/user", opts))
  assert(stat == 200)
  return assert(DecodeJson(body))
end

function github.cache_avatar(user_info)
  if assert(unix.fork()) == 0 then -- async download avatar
    local url = ParseUrl(assert(user_info.avatar_url))
    table.insert(url.params, {"s", "20"}) -- prefer 20x20 image
    local stat, headers, body = assert(Fetch(assert(EncodeUrl(url))))
    assert(stat == 200)
    local ct = assert(headers["Content-Type"])
    -- TODO: put these in different database?
    local dbscope <close> = db.open()
    db.urow([[
    REPLACE INTO avatar_cache(user_id, body, content_type) VALUES (?, ?, ?)
    ]], assert(db.user_id), EncodeBase64(body), ct)
    unix.exit(0)
  end
end

if not path.exists(DB_FILE) then
  local schema = assert(Slurp"/zip/schema.sql")

  local dbscope <close> = db.open()
  db.exec(schema)

  db.exec(assert(Slurp"test.sql"))

  for puzzle_id in db.urows"SELECT rowid FROM puzzle" do
    fill_bucket(puzzle_id, config.BUCKET_AMOUNT)
  end

  Log(kLogInfo, "Database initialized at '" .. DB_FILE .. "'")
end


local routes = {}

for _, v in ipairs {
  "about", "events", "index", "leaderboard", "login", "logout", "profile",
  "puzzle-answer", "puzzle-index", "puzzle-input", "puzzle-leaderboard",
  "puzzle-submit", "stats", "updateprofile"
} do
  routes[v] = assert(loadfile(v..".lua"))
end


function OnHttpRequest()
  local p = GetPath()

  if p == "/style.css" then return ServeAsset("/style.css") end

  local uid = p:match"^/avatar%-(%d+)"
  if uid then
    local dbscope <close> = db.open()
    local body, ct = db.urow([[
    SELECT body, content_type
    FROM avatar_cache
    WHERE user_id = ?
    ]], tonumber(uid))
    if not body then return ServeError(404) end
    SetStatus(200)
    --TODO: cache/not modified header thing?
    SetHeader("Content-Type", ct)
    return Write(DecodeBase64(body))
  end

  db.event_name = p:match"^/(%d+)"
  if db.event_name then p = p:sub(#db.event_name+2) end

  db.puzzle_name = p:match"^/day/(%d+)"
  if db.puzzle_name then p = p:sub(#db.puzzle_name+6) end

  local cmd = p:match"^/(%l*)$"
  if not cmd or cmd == "" then cmd = "index" end
  if db.puzzle_name then cmd = "puzzle-" .. cmd end

  if not routes[cmd] then return ServeError(404) end

  local dbscope <close> = db.open()
  db.user_id = db.get_session_user_id()

  db.puzzle_id = db.puzzle_name and db.urow("SELECT rowid FROM puzzle WHERE name = ?", db.puzzle_name)

  db.event_name = db.event_name or current_event
  db.event_id = db.urow("SELECT rowid FROM event WHERE name = ?", event_name)

  routes[cmd]()
end

function OnServerHeartbeat()
  --TODO: probably horribly inefficient
  --TODO: fork here? permissions?
  local dbscope <close> = db.open()

  db.exec[[
  BEGIN TRANSACTION;

  --TODO: don't use same interval as leaderboard update
  UPDATE write_limiter SET writes = 0;

  DELETE FROM leaderboard;

  INSERT INTO leaderboard(user_id, score)
  SELECT user_id, score FROM all_silver;

  UPDATE leaderboard
  SET score = leaderboard.score + all_gold.score
  FROM all_gold
  WHERE all_gold.user_id = leaderboard.user_id;

  COMMIT;
  ]]
end

ProgramHeartbeatInterval(config.LEADERBOARD_INTERVAL * 1000) -- 10s
