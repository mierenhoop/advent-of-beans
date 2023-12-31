local link = GetParam"link"
local anon = GetParam"anonymous"

if not link then return ServeError(400) end

if link == "" then link = nil end-- TODO: parse url

if not db.user_id then
  Log(kLogWarn, "no cookie")
  return ServeRedirect(303, html.link"profile")
end

if db.write_limiter() then return end

if not anon then
  local gh_auth = db.urow("SELECT gh_auth FROM user WHERE rowid = ?", db.user_id)
  local user_info = github.fetch_user(gh_auth)
  local name = assert(user_info.login)
  db.urow([[
  UPDATE user
  SET name = ?, link = ?, anonymous = false
  WHERE rowid = ?]], name, link, db.user_id)

  github.cache_avatar(user_info)
else
  db.urow("UPDATE user SET link = ?, anonymous = true WHERE rowid = ?",
  link, db.user_id)
  db.urow("DELETE FROM avatar_cache WHERE user_id = ?", db.user_id)
end


ServeRedirect(303, html.link"profile")
