if not db.user_id then return ServeError(400) end

local bucket = db.get_user_bucket(db.user_id, db.puzzle_id)

local time_start = db.urow([[
SELECT time_start
FROM puzzle WHERE rowid = ?
]], db.puzzle_id)

if GetTime() < time_start then return ServeError(403) end

local input = db.urow([[
SELECT input
FROM bucket
WHERE rowid = ?
]], bucket)

SetHeader("Content-Type", "text/plain")
Write(input)
