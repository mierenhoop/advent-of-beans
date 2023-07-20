local user_id = db.get_session_user_id()

if not user_id then
  Log(kLogWarn, "no cookie")
  return ServeRedirect(303, "/profile")
end

if not puzzle then return ServeError(400) end

local cookie = DecodeJson(DecodeBase64(GetCookie(COOKIE_ANSWER)))
if not cookie then
  Log(kLogWarning, "user visited answer with expired cookie")
  return ServeError(400)
end

if type(cookie) ~= "table"
  or (cookie.target ~= "gold" and cookie.target ~= "silver") then
  return ServeError(400)
end

local fails, next_try = db.urow([[
SELECT fails, next_try FROM user
WHERE rowid = ?
]], user_id)

local answer_time = db.urow(fmt([[
SELECT %s_time FROM user_puzzle
WHERE user_id = ?
AND puzzle = ?
]], cookie.target), user_id, puzzle)

html.page_begin()

if next_try and GetTime() < next_try then
  wrt(fmt("<p>Your answer was %s</p>", esc(cookie.fail_msg))) --TODO: don't show when still waiting
  wrt(fmt("<p>Wait %.0f seconds</p>", next_try - GetTime()))
elseif answer_time then
  -- TODO: floating point rounding errors?? else just store time as integer
  wrt(fmt([[
  <p>Your received the <strong>%s</strong> star.</p>
  <p>Finished puzzle in %.2f seconds.</p>
  ]], cookie.target, answer_time))
  local place = db.urow(fmt([[
  SELECT COUNT(silver_time)
  FROM user_puzzle
  WHERE puzzle = ?
  AND %s_time <= ?
  ]], cookie.target), puzzle, answer_time)
  wrt(fmt([[
  <p>You placed %d</p>
  ]], place)) --TODO: use consistent view
else
  return ServeError(400)
end

wrt(fmt([[<p>Go back to <a href="/%s">the puzzle</a></p>]], puzzle))

html.page_end()
