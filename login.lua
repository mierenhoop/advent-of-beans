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
    "client_id="..EscapeParam(github.client_id),
    "client_secret="..EscapeParam(github.client_secret),
    "code="..EscapeParam(code),
  }, "&"),
}

local gh_at_link = "https://github.com/login/oauth/access_token"

-- TODO: protect this expensive call from malicious DOS'ers
local stat, _, body = assert(Fetch(gh_at_link, opts))
assert(stat == 200)

local token = assert(assert(DecodeJson(body)).access_token)
local user_json = github.fetch_user(token)

local gh_id = assert(user_json.id)

local user_id = db.urow("SELECT rowid FROM user WHERE gh_id = ?", gh_id)

if not user_id then
  user_id = db.urow([[
  INSERT INTO user(name, link, gh_id, gh_auth)
  VALUES (?, ?, ?, ?)
  RETURNING rowid]],
  assert(user_json.login), assert(user_json.html_url), gh_id, token)
  for puzzle_id in db.urows"SELECT rowid FROM puzzle" do
    db.get_user_bucket(user_id, puzzle_id) -- add bucket to user
  end
end

local cookie = EncodeBase64(GetRandomBytes(18))

db.urow("DELETE FROM session WHERE user_id = ?", user_id)
db.urow("INSERT INTO session(user_id, token) VALUES (?, ?)", user_id, cookie)

SetStatus(303)
SetCookie(db.cookie_key, cookie)

return SetHeader("Location", html.link"profile")
