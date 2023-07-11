local time = GetTime() -- first to get most accurate reading

local answer = tonumber(GetParam"answer")
local target = GetParam"type"

if not answer
  or (target ~= "silver" and target ~= "gold")
  or not puzzle then
  return ServeError(400)
end

local user_id = db.get_session_user_id()
if not user_id then return ServeError(400) end -- TODO: or not authorized?

local bucket, fails, next_try, puzzle_time = db.urow(fmt([[
SELECT bucket_id, fails, next_try, %s_time
FROM user_puzzle 
WHERE user_id = ?
  AND puzzle = ?
]], target), user_id, puzzle)

-- TODO: use this only once in this/answer.lua
if next_try and GetTime() < next_try then
  return ServeRedirect(303, fmt("/%s/answer",puzzle))
end

if puzzle_time then return ServeError(400) end -- already correct answer

local target_answer = db.urow(fmt([[
SELECT %s_answer
FROM bucket
WHERE rowid = ?
]], target), bucket)

if answer == target_answer then
  local time_start = db.urow([[
  SELECT time_start
  FROM puzzle
  WHERE name = ?
  ]], puzzle)

  --TODO: use plain files to combat sqlite write lock
  --local timefmt = "/tmp/time-%s-%d-%d"
  --Barf(fmt(timefmt, "gold", puzzle_id, user_id), tostring(time), 0644, unix.O_WRONLY|unix.O_CREAT|unix.O_EXCL)
  db.urow(fmt([[
  UPDATE user_puzzle
  SET %s_time = ?, fails = 0
  WHERE puzzle = ?
  AND user_id = ?
  ]], target), time-time_start, puzzle, user_id)

  Log(kLogInfo, fmt("user %d got puzzle %d at %f", user_id, puzzle, time))
else
  fails = fails + 1
  -- 1 > 10s
  -- 2 > 30s
  -- 3 > 60s
  -- 4+ > 120s
  local waiting_time = ({[1]=10,[2]=30,[3]=60,[4]=120})[math.min(fails, 4)]

  db.urow([[
  UPDATE user_puzzle
  SET fails = ?,
  next_try = ?
  WHERE user_id = ?
  AND puzzle = ?
  ]], fails, GetTime() + waiting_time, user_id, puzzle)
  Log(kLogInfo, fmt("user %d failed puzzle %d", user_id, puzzle))
end

ServeRedirect(303, fmt("/%s/answer",puzzle))
