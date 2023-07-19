--TODO: rate limit this...

local link = GetParam"link"
local anon = GetParam"anonymous"

if not link then return ServeError(400) end

if link == "" then link = nil end-- TODO: parse url

local user_id = db.get_session_user_id()

if not user_id then
  Log(kLogWarn, "no cookie")
  return ServeRedirect(303, "/profile")
end

if not anon then
  local gh_auth = db.urow("SELECT gh_auth FROM user WHERE rowid = ?", user_id)
  local user_info = Github.fetch_user(gh_auth)
  local name = assert(user_info.login)
  db.urow([[
  UPDATE user
  SET name = ?, link = ?, anonymous = false
  WHERE rowid = ?]], name, link, user_id)

  Github.cache_avatar(user_info)
else
  db.urow("UPDATE user SET link = ?, anonymous = true WHERE rowid = ?",
  link, user_id)
end


ServeRedirect(303, "/profile")
