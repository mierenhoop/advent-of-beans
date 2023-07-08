local db = require "db"

--TODO: rate limit this...

local link = GetParam"link"

if not link then return ServeError(400) end

if link == "" then link = nil end-- TODO: parse url

local user_id = db.get_session_user_id()

if not user_id then
  Log(kLogWarn, "no cookie")
  return ServeRedirect(303, "/profile.lua")
end

db.urow("UPDATE user SET link = ? WHERE id = ?", link, user_id)

ServeRedirect(303, "/profile.lua")
