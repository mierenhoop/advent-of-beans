if MDB then MDB.on() end

local db = require "db"
local html = require "html"
local wrt, fmt, esc = Write, string.format, EscapeHtml

local puzzle_id = tonumber(GetParam"id")
if not puzzle_id then return ServeError(400) end

local name, h, time_start = db.urow([[
SELECT name, html, time_start
FROM puzzle WHERE id = ?
]], puzzle_id)

if not name then return ServeError(400) end

if time_start > GetTime() then return ServeError(403) end

html.page_begin()

wrt("<h1>"..esc(name).."</h1>")
local p1, p2
do
  local i, j = h:find("$PART2$", 1, true)
  p1, p2 = h:sub(1, i-1), h:sub(j+1)
end

wrt(p1)

local user_id = db.get_session_user_id()

if not user_id then
  wrt[[<p><strong>Log in to play</strong></p>]]
  html.page_end()
  return
end

db.get_user_bucket(user_id, puzzle_id)

local silver_time, gold_time = db.urow([[
SELECT silver_time, gold_time
FROM user_puzzle
WHERE
  puzzle_id = ?
  AND user_id = ?
]], puzzle_id, user_id)
--silver_time = db.urow([[
--SELECT time
--FROM achievement
--WHERE
--  puzzle_id = ?
--  AND user_id = ?
--  AND type = 'silver'
--]], puzzle_id, user_id)


local function html_input(atype)
  wrt[[
  <form action="/submit.lua" method="POST">]]
  wrt(fmt([[
  <input type="hidden" name="type" value="%s" />
  <input type="hidden" name="puzzle" value="%d" />
  ]], atype, puzzle_id))
  wrt[[<input type="number" name="answer" placeholder="answer"/>
  <button type="submit">Submit</button>
  </form>
  ]]
end

local function html_receive(atype, answer)
  wrt(fmt([[
  <strong>Received <em>%s</em> star</strong>
  <form>
  <input disabled value="%s" />
  </form>
  ]], atype, answer))

end

local bucket = db.get_user_bucket(user_id, puzzle_id)
local silver_answer, gold_answer = db.urow([[
SELECT silver_answer, gold_answer
FROM bucket WHERE id = ?
]], bucket)

if silver_time then
  html_receive("silver", silver_answer)

  wrt(p2)

  if not gold_time then
    html_input"gold"
    wrt(fmt([[
    <p>You can still <a href="/input.lua?puzzle=%d">get your input</a></p>
    ]], puzzle_id))
  else
    html_receive("gold", gold_answer)
  end
else
  html_input"silver"
  wrt(fmt([[
  <p><a href="/input.lua?puzzle=%d">Get your input</a></p>
  ]], puzzle_id))
end

html.page_end()
