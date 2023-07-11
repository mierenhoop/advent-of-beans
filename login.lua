local name = GetParam"name"
if not name then return ServeError(400) end

local user_id = tonumber(name)
if not user_id then return ServeError(400) end

if db.urow("SELECT 1 FROM user WHERE rowid = ?", user_id) ~= 1 then
  return ServeError(400) -- user not found
end

-- TODO: make sure unique token
local token = EncodeBase64(GetRandomBytes(18))

db.urow("DELETE FROM session WHERE user_id = ?", user_id)
db.urow("INSERT INTO session(user_id, token) VALUES (?, ?)", user_id, token)

SetStatus(303)
SetCookie(COOKIE_KEY, token)

return SetHeader("Location", "/profile")
