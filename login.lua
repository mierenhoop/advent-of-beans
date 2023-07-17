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
--TODO: should we use this token as cookie? probably not? hash this token?
local token = assert(assert(DecodeJson(body)).access_token)

local opts = {
  method = "GET",
  headers = {
    ["Accept"] = "application/vnd.github+json",
    ["Authorization"] = "Bearer " .. token,
    ["X-GitHub-Api-Version"] = "2022-11-28",
  },
}
local stat, _, body = assert(Fetch("https://api.github.com/user", opts))
assert(stat == 200)
local user_json = assert(DecodeJson(body))
local name, link = assert(user_json.login), assert(user_json.html_url)

local user_id = db.urow("INSERT INTO user(name, link) VALUES (?, ?) RETURNING rowid", name, link)

local cookie = EncodeBase64(GetRandomBytes(18))

db.urow("DELETE FROM session WHERE user_id = ?", user_id)
db.urow("INSERT INTO session(user_id, token) VALUES (?, ?)", user_id, cookie)

SetStatus(303)
SetCookie(COOKIE_KEY, cookie)

return SetHeader("Location", "/profile")
