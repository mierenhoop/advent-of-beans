local user_id = db.get_session_user_id()
if not user_id then return ServeError(400) end

local bucket = db.get_user_bucket(user_id, puzzle)

local time_start = db.urow([[
SELECT time_start
FROM puzzle WHERE name = ?
]], puzzle)

if GetTime() < time_start then return ServeError(403) end

local input = db.urow([[
SELECT input
FROM bucket
WHERE rowid = ?
]], bucket)

SetHeader("Content-Type", "text/plain")
wrt(input)
