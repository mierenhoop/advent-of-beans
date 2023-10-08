if not db.user_id then
  Log(kLogWarn, "no cookie")
  return ServeRedirect(303, "/profile")
end

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
]], db.user_id)

local answer_time = db.urow([[
SELECT time FROM achievement
WHERE user_id = ?
AND puzzle_id = ?
AND type = ?
]], db.user_id, puzzle_id, cookie.target)

html.page_begin()

if next_try and GetTime() < next_try then
  wrt(fmt("<p>Your answer was %s</p>", esc(cookie.fail_msg))) --TODO: don't show when still waiting
  wrt(fmt("<p>Wait %.0f seconds</p>", next_try - GetTime()))
elseif answer_time then
  -- TODO: floating point rounding errors?? else just store time as integer
  wrt(fmt([[
  <p>Your received the <strong class="stat-%s">%s</strong> star.</p>
  <p>Finished puzzle in %.2f seconds.</p>
  ]], cookie.target, cookie.target, answer_time))
  local place = db.urow([[
  SELECT COUNT(time) FROM achievement
  WHERE puzzle_id = ? AND type = ?
  AND rowid <= ? --TODO:BETWEEN
  ]], puzzle_id, cookie.target, assert(cookie.bucketrow))
  wrt(fmt([[
  <p>You placed %d</p>
  ]], place)) --TODO: use consistent view
else
  return ServeError(400)
end

wrt(fmt([[<p>Go back to <a href="/%s">the puzzle</a></p>]], puzzle_name))

html.page_end()
