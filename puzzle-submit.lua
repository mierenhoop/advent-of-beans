local answer = tonumber(GetParam"answer")
local target = GetParam"type"

if not answer
  or (target ~= "silver" and target ~= "gold")
  or not puzzle then
  return ServeError(400)
end

local user_id = db.get_session_user_id()
if not user_id then return ServeError(400) end -- TODO: or not authorized?

local fails, next_try = db.urow([[
SELECT fails, next_try
FROM user
WHERE rowid = ?
]], user_id)

local bucket, puzzle_time = db.urow(fmt([[
SELECT bucket_id, %s_time
FROM user_puzzle 
WHERE user_id = ?
  AND puzzle = ?
]], target), user_id, puzzle)

-- TODO: use this only once in this/answer.lua
if next_try and GetTime() < next_try then
  return ServeRedirect(303, fmt("/%s/answer",puzzle))
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
    ]], user_id)
    local pos = db.urow(([[
    UPDATE puzzle
    SET STAR_size = STAR_size + 1
    WHERE name = ?
    RETURNING STAR_size
    ]]):gsub("STAR",target), puzzle)
    cookie.pos = pos
    db.urow(fmt([[
    UPDATE user_puzzle
    SET %s_time = UNIXEPOCH()-(SELECT time_start FROM puzzle WHERE name = ?)
    WHERE puzzle = ?
    AND user_id = ?
    ]], target), puzzle, puzzle, user_id)
  end)

  Log(kLogInfo, fmt("user %d got puzzle %s", user_id, puzzle))
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
  ]], fails, waiting_time, user_id)
  Log(kLogInfo, fmt("user %d failed puzzle %d", user_id, puzzle))
end

SetCookie(COOKIE_ANSWER, EncodeBase64(EncodeJson(cookie))) -- TODO: expire 10s

SetHeader("Location", fmt("/%s/answer",puzzle))
