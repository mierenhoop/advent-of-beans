html.page_begin()

if db.user_id then
  if db.write_limiter() then return end

  local name, link, anon = db.urow("SELECT name, link, anonymous FROM user WHERE rowid = ?", db.user_id)
  anon = anon ~= 0

  wrt"<p>Logged in as: <strong>"
  html.user(db.user_id, anon, name, link)
  wrt"</strong></p>"

  local silver, gold = db.urow([[
  SELECT COUNT(nullif(type = 'silver',0)), COUNT(nullif(type = 'gold',0))
  FROM achievement
  WHERE user_id = ?
  ]], db.user_id)
  wrt(fmt([[
  <p>You have in total <strong>%d <em>silver</em></strong>
  and <strong>%d <em>gold</em></strong> stars.</p>
  ]], silver, gold))

  wrt(fmt([[
  <form action="/updateprofile" method="POST">
  <input type="url" name="link" placeholder="Link (optional)" value="%s">
  <label for="anonymous">Anonymous?</label>
  <input type="checkbox" id="anonymous" %s name="anonymous">
  <button type="submit">Update</button>
  </form>
  ]], esc(link or ""), anon and "checked" or ""))
  -- method don't really matter here
  wrt[[<br><form action="/logout">
  <button type="submit">Logout</button>
  </form>
  ]]
else
  local redir = ParseUrl(GetUrl())
  redir.path="/login"

  local link = "https://github.com/login/oauth/authorize"
  .. "?scope="
  .. "&client_id=" .. EscapeParam(GH_CLIENT_ID)
  --.. "&redirect_uri=" .. EscapeParam(EncodeUrl(redir))

  wrt(fmt([[
  <a href="%s">
  [Login with Github]
  </a>
  ]], esc(link)))
  --wrt[[
  --<form action="/login" method="POST">
  --<input type="text" name="name" placeholder="name" />
  --<button type="submit">Login</button>
  --</form>
  --]]
end
html.page_end()
