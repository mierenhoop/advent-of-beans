local exe = arg[-1]
local exedir = path.dirname(exe)

local defaultdb = path.join(exedir, "aob.db")
DB_FILE = os.getenv"AOB_DB_FILE" or defaultdb

GH_CLIENT_ID = assert(os.getenv"AOB_GH_CLIENT_ID")
GH_CLIENT_SECRET = assert(os.getenv"AOB_GH_CLIENT_SECRET")

COOKIE_KEY="advent_session"
COOKIE_ANSWER="advent_answer"

LEADERBOARD_INTERVAL = 3
BUCKET_AMOUNT=1000

MAX_WRITES=10

db = {}
html = {}
Github = {}
wrt, fmt, esc = Write, string.format, EscapeHtml

function db.open()
  local pid = unix.getpid()
  assert(db.curpid ~= pid, "db: already open in current process")

  db._db = assert(lsqlite3.open(DB_FILE), "db: could not open")
  db.curpid = pid
  Log(kLogInfo, "db: open, pid: " .. pid)

  db._db:busy_timeout(1000)
  -- TODO: these PRAGMA's are relatively expensive
  pcall(db.exec, [[
  PRAGMA journal_mode=wal;
  PRAGMA synchronous=normal;
  ]])
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
  local stmt = prep(sql, ...)
  local rows = table.pack(stmt:urows()(stmt))
  dbok(stmt:finalize())
  return table.unpack(rows)
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
  html[[<a href="/about">About</a> | ]]
  html[[<a href="/events">Events</a> | ]]
  html[[<a href="/leaderboard">Leaderboard</a> | ]]
  html[[<a href="/stats">Stats</a> | ]]
  local name
  if db.user_id then
    name = db.urow("SELECT name FROM user WHERE rowid = ?", db.user_id)
  end
  html([[<a href="/profile">%s</a>]], name and EscapeHtml(name) or "Login")

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
  for name in db.urows"SELECT name FROM puzzle ORDER BY time_start" do
    local link = name
    name = EscapeHtml(name)
    if name == puzzle_name then name = "<strong>"..name.."</strong>" end
    html([[ <a href="/%s/leaderboard">%s</a>]], link, name)
  end
  html[[</p>]]
end

function html.user(user_id, anon, name, link)
  --TODO: avatar
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

function html.link(puzzle, event)
  local link = "/"..(event or current_event)
  if puzzle then
    return link.."/"..puzzle
  end
  return link
end

function Github.fetch_user(gh_auth)
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

function Github.cache_avatar(user_info)
  if assert(unix.fork()) == 0 then -- async download avatar
    local url = ParseUrl(assert(user_info.avatar_url))
    print(EncodeLua(url), user_info.avatar_url)
    table.insert(url.params, {"s", "20"}) -- prefer 20x20 image
    local stat, headers, body = assert(Fetch(assert(EncodeUrl(url))))
    assert(stat == 200)
    print(EncodeLua(headers))
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
    fill_bucket(puzzle_id, BUCKET_AMOUNT)
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

  local cmd

  puzzle_name, cmd = p:match"^/(%d%d?)/?(%l*)$"
  if not cmd then cmd = p:match"^/(%l*)$" end
  if not cmd then return ServeError(404) end
  if cmd == "" then cmd = "index" end
  if puzzle_name then cmd = "puzzle-" .. cmd end

  --print("Access", "/"..cmd..".lua")

  local dbscope <close> = db.open()
  db.user_id = db.get_session_user_id()

  if puzzle_name then
    -- global TODO: don't do this
    puzzle_id = db.urow("SELECT rowid FROM puzzle WHERE name = ?", puzzle_name)
  end

  routes[cmd]()
  local url = GetHost(), "/"..cmd..".lua?event="..EscapeParam(current_event)
  if puzzle_name then url = url.."&puzzle="..EscapeParam(puzzle_name) end
  --return Route(url)
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

ProgramHeartbeatInterval(LEADERBOARD_INTERVAL * 1000) -- 10s
