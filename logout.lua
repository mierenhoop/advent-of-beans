local db = require"db"
local user_id = db.get_session_user_id()
if user_id then
  db.urow("DELETE FROM session WHERE user_id = ?", user_id)
end

SetStatus(303)
SetCookie(COOKIE_KEY, "", { expires = 0 })
return SetHeader("Location", "/profile.lua")
