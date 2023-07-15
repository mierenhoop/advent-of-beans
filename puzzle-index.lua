local p1, p2, time_start = db.urow([[
SELECT part1, part2, time_start
FROM puzzle WHERE name = ?
]], puzzle)

if not time_start then return ServeError(400) end

if time_start > GetTime() then return ServeError(403) end

html.page_begin()

wrt("<h1>"..esc(puzzle).."</h1>")

wrt(p1)

local user_id = db.get_session_user_id()

if not user_id then
  wrt[[<p><strong>Log in to play</strong></p>]]
  html.page_end()
  return
end

db.get_user_bucket(user_id, puzzle)

local silver_time, gold_time = db.urow([[
SELECT silver_time, gold_time
FROM user_puzzle
WHERE
  puzzle = ?
  AND user_id = ?
]], puzzle, user_id)

local function html_input(atype)
  wrt(fmt([[
  <form action="/%s/submit" method="POST">]], puzzle))
  wrt(fmt([[
  <input type="hidden" name="type" value="%s" />
  ]], atype))
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

local bucket = db.get_user_bucket(user_id, puzzle)
local silver_answer, gold_answer = db.urow([[
SELECT silver_answer, gold_answer
FROM bucket WHERE rowid = ?
]], bucket)

if silver_time then
  html_receive("silver", silver_answer)

  wrt(p2)

  if not gold_time then
    html_input"gold"
    wrt(fmt([[
    <p>You can still <a href="/%s/input">get your input</a></p>
    ]], puzzle))
  else
    html_receive("gold", gold_answer)
  end
else
  html_input"silver"
  wrt(fmt([[
  <p><a href="/%s/input">Get your input</a></p>
  ]], puzzle))
end

html.page_end()
