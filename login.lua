local code = GetParam"code"

if not code then
  return ServeError(400)
end

local opts = {
  method = "POST",
  headers = {
    ["Accept"] = "application/json",
  },
  body = table.concat({
    "client_id="..EscapeParam(GH_CLIENT_ID),
    "client_secret="..EscapeParam(GH_CLIENT_SECRET),
    "code="..EscapeParam(code),
  }, "&"),
}

local gh_at_link = "https://github.com/login/oauth/access_token"

local stat, _, body = assert(Fetch(gh_at_link, opts))
assert(stat == 200)

local token = assert(assert(DecodeJson(body)).access_token)
local user_json = github_fetch_user(token)

local gh_id = assert(user_json.id)

local user_id = db.urow("SELECT rowid FROM user WHERE gh_id = ?", gh_id)

if not user_id then
  user_id = db.urow([[
  INSERT INTO user(name, link, gh_id, gh_auth)
  VALUES (?, ?, ?, ?)
  RETURNING rowid]],
  assert(user_json.login), assert(user_json.html_url), gh_id, token)

  -- TODO: cache avatar when user calls updateprofile.lua
  --if assert(unix.fork()) == 0 then -- async download avatar
  --  local url = ParseUrl(assert(user_json.avatar_url))
  --  table.insert(url.params, {"s", "20"}) -- get 20x20 image
  --  stat, _, body = assert(Fetch(assert(EncodeUrl(url))))
  --  print(EncodeUrl(url))
  --  assert(stat == 200)
  --  local avatar = EncodeBase64(body)
  --  db.urow("UPDATE user SET avatar = ?", avatar)
  --  unix.exit(0)
  --end
end

local cookie = EncodeBase64(GetRandomBytes(18))

db.urow("DELETE FROM session WHERE user_id = ?", user_id)
db.urow("INSERT INTO session(user_id, token) VALUES (?, ?)", user_id, cookie)

SetStatus(303)
SetCookie(COOKIE_KEY, cookie)

return SetHeader("Location", "/profile")
