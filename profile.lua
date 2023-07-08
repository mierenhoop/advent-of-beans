local db = require"db"

local html = require"html"
local wrt, fmt = Write, string.format

html.page_begin()

local user_id = db.get_session_user_id()
if user_id then
  local name, link = db.urow("SELECT name, link FROM user WHERE id = ?", user_id)

  wrt(fmt([[
  <p>Logged in as: <strong>%s</strong></p>
  ]], EscapeHtml(name)))

  local silver, gold = db.urow([[
  SELECT COUNT(silver_time), COUNT(gold_time)
  FROM user_puzzle
  WHERE user_id = ?
  ]], user_id)
  wrt(fmt([[
  <p>You have in total <strong>%d <em>silver</em></strong>
  and <strong>%d <em>gold</em></strong> stars.</p>
  ]], silver, gold))

  wrt(fmt([[
  <form action="/update-profile.lua" method="POST">
  <input type="url" name="link" placeholder="Link (optional)" value="%s">
  <button type="submit">Update</button>
  </form>
  ]], EscapeHtml(link or "")))
  -- method don't really matter here
  wrt[[<form action="/logout.lua">
  <button type="submit">Logout</button>
  </form>
  ]]
else
  wrt[[
  <form action="/login.lua" method="POST">
  <input type="text" name="name" placeholder="name" />
  <button type="submit">Login</button>
  </form>
  ]]
end

html.page_end()
