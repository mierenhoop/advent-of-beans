local answer = tonumber(GetParam"answer")
local target = GetParam"type"

if not answer
  or (target ~= "silver" and target ~= "gold") then
  return ServeError(400)
end

if not db.user_id then return ServeError(400) end -- TODO: or not authorized?

if db.write_limiter() then return end

local fails, next_try = db.urow([[
SELECT fails, next_try
FROM user
WHERE rowid = ?
]], db.user_id)

local bucket, puzzle_time = db.urow([[
SELECT
(SELECT bucket_id
FROM user_puzzle
WHERE user_id = ? AND puzzle_id = ?),
(SELECT time
FROM achievement
WHERE user_id = ? AND puzzle_id = ? AND type = ?)
]], db.user_id, puzzle_id, db.user_id, puzzle_id, target)

-- TODO: use this only once in this/answer.lua
if next_try and GetTime() < next_try then
  return ServeRedirect(303, fmt("/%s/answer",puzzle_name))
end

if puzzle_time then return ServeError(400) end -- already correct answer

SetStatus(303)

local cookie = { target = target }

local target_answer = db.urow(fmt([[
SELECT %s_answer
FROM bucket
WHERE rowid = ?
]], target), bucket)

if answer == target_answer then
  db.transaction(function()
    db.urow([[
    UPDATE user
    SET fails = NULL
    WHERE rowid = ?
    ]], db.user_id)
    cookie.bucketrow = db.urow([[
    INSERT INTO achievement(user_id, puzzle_id, time, type) VALUES
    (?, ?, UNIXEPOCH()-(SELECT time_start FROM puzzle WHERE rowid = ?), ?)
    RETURNING rowid
    ]], db.user_id, puzzle_id, puzzle_id, target)
  end)

  Log(kLogInfo, fmt("user %d got puzzle %s", db.user_id, puzzle_name))
else
  fails = (fails or 0)+ 1
  -- 1 > 10s
  -- 2 > 30s
  -- 3 > 60s
  -- 4+ > 120s
  local waiting_time = ({[1]=10,[2]=30,[3]=60,[4]=120})[math.min(fails, 4)]

  cookie.fail_msg = "not correct"
  if type(target_answer) == "number" then
    cookie.fail_msg = answer < target_answer and "too low" or "too high"
  end

  db.urow([[
  UPDATE user
  SET fails = ?,
  next_try = UNIXEPOCH()+?
  WHERE rowid = ?
  ]], fails, waiting_time, db.user_id)
  Log(kLogInfo, fmt("user %d failed puzzle %d", db.user_id, puzzle_name))
end

SetCookie(COOKIE_ANSWER, EncodeBase64(EncodeJson(cookie))) -- TODO: expire 10s

SetHeader("Location", fmt("/%s/answer",puzzle_name))
