local sqlite = require "lsqlite3"

---@diagnostic disable-next-line
local unpack = unpack or table.unpack

local db = {}

local _db = sqlite.open(DB_FILE)
_db:busy_timeout(1000)
--local _db = sqlite.open_memory()

--_db:trace(function(_,sql)
--  print("\x1b[1;31m" .. "Executed SQL" .. "\x1b[0m")
--  print(sql)
--end)

local prepcache = {}

--TODO: make sure prepcache doesn't persist after fork
-- for now commented out...
local function prep(sql, ...)
  --if not prepcache[sql] then
    local stmt = _db:prepare(sql)
    if stmt == nil then error(_db:errmsg()) end
    prepcache[sql] = stmt
  --else
    --local r = prepcache[sql]:reset() 
    --assert(r == sqlite.OK)
  --end
  local stmt = prepcache[sql]
  assert(stmt:bind_values(...) == sqlite.OK)
  return stmt
end

function db.exec(sql)
  local ret = _db:exec(sql)
  if ret ~= sqlite.OK then
    error(_db:errmsg())
  end
  --local stmt = prep(sql, ...)
  --assert(stmt:step() == sqlite.DONE)
end

function db.urow(sql, ...)
  local stmt = prep(sql, ...)
  return stmt:urows()(stmt)
end

function db.urows(sql, ...)
  local stmt = prep(sql, ...)
  return stmt:urows(), stmt
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
  SELECT gen_code FROM puzzle WHERE id = ?
  ]], puzzle_id)
  local f = assert(load(code))

  local entropy = os.time()

  for i = 1, amount do
    math.randomseed(entropy+i)
    local input, silver, gold = f()
    assert(input and silver)
    db.urow([[
    INSERT INTO bucket(puzzle_id, input, silver_answer, gold_answer) VALUES (?, ?, ?, ?)
    ]], puzzle_id, input, silver, gold)
  end
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
    SELECT id
    FROM bucket
    WHERE puzzle_id = ?
    ORDER BY RANDOM()
    LIMIT 1;
    ]], puzzle_id)
    if not bucket then
      fill_bucket(puzzle_id, 10)
      goto randombucket
    end
    db.urow([[
    INSERT INTO user_puzzle(user_id, puzzle_id, bucket_id)
    VALUES (?, ?, ?)
    ]], user_id, puzzle_id, bucket)
  end
  return bucket
end

-----@type fun(id: integer): string
--db.user_get_name = fetchone "SELECT name FROM user WHERE id = ?"
--
-----@type fun(name: string, link: string | nil)
--db.user_add = execprep "INSERT INTO user(name, link) values (?, ?)"
--
--local user_finish = execprep "INSERT INTO achievement VALUES (?, ?, ?, ?)"
--
-----@alias achievement "silver" | "gold"
--
-----@param user_id integer
-----@param puzzle_id integer
-----@param a_type achievement
-----@return boolean, string|nil
--db.achievement_add = function(user_id, puzzle_id, a_type)
--  local time = os.time()
--  return user_finish(user_id, puzzle_id, time, a_type)
--end
--
-----@type fun(a_type: achievement, amount: integer, offset: integer): {user_id: integer, time: integer}[]
--db.achievement_get_leaderboard = fetchall [[
--SELECT user_id, time
--FROM achievement
--WHERE type = ?
--ORDER BY
--  time ASC,
--  user_id
--LIMIT ?
--OFFSET ?;
--]]
--
--db.puzzle_add = function(name, time_start, gen_code)
--  local f, err = load(gen_code)
--  if f == nil or not pcall(f) then
--    return false, err
--  end
--
--  return puzzle_add(name, time_start, gen_code)
--end
--
--local puzzle_get_code = fetchone "SELECT gen_code FROM puzzle WHERE id = ?;"
--
--local bucket_add = execprep "INSERT INTO bucket(puzzle_id, input, answer) VALUES (?, ?, ?)"
--
--db.fill_buckets = function(puzzle_id, amount)
--  local code = assert(puzzle_get_code(puzzle_id))
--  local f = assert(load(code))
--
--  local entropy = os.time()
--
--  for i = 1, amount do
--    math.randomseed(entropy+i)
--    local input, answer = f()
--    assert(input and answer)
--    assert(bucket_add(puzzle_id, input, answer))
--  end
--end
--
--local get_bucket = fetchone [[
--SELECT id
--FROM bucket
--WHERE puzzle_id = ?
--ORDER BY RANDOM()
--LIMIT 1;
--]]
--
--local add_user_puzzle = execprep "INSERT INTO user_puzzle VALUES (?, ?, ?, ?, ?);"
--
--db.user_puzzle_assign = function(user_id, puzzle_id)
--  local bucket_id = assert(get_bucket(puzzle_id))
--
--  return add_user_puzzle(user_id, puzzle_id, bucket_id)
--end
--
--
--db.get_puzzles = fetchall [[
--SELECT *
--FROM puzzle
--ORDER BY time_start ASC;
--]]
--
--local id = assert(db.get_puzzles())[1].id
--
--db.fill_buckets(id, 10)

--local b = sqlite.backup_init(sqlite.open"/tmp/out.db", "main", _db, "main")
--if b then
--  b:step(-1)
--  b:finish()
--end

return db
