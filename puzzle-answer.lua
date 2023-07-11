local user_id = db.get_session_user_id()

if not user_id then
  Log(kLogWarn, "no cookie")
  return ServeRedirect(303, "/profile")
end

if not puzzle then return ServeError(400) end

local silver_time, gold_time, fails, next_try = db.urow([[
SELECT silver_time, gold_time, fails, next_try FROM user_puzzle
WHERE user_id = ?
AND puzzle = ?
]], user_id, puzzle)

local answer_time = gold_time or silver_time

html.page_begin()

if next_try and GetTime() < next_try then
  wrt(fmt("<p>Wait %.0f seconds</p>", next_try - GetTime()))
elseif fails > 0 then
  wrt(fmt([[<p>You failed at attempt %d</p>]], fails))
elseif answer_time then
  -- TODO: floating point rounding errors?? else just store time as integer
  local target = (answer_time == gold_time) and "gold" or "silver"
  wrt(fmt([[
  <p>Your received the <strong>%s</strong> star.</p>
  <p>Finished puzzle in %.2f seconds.</p>
  ]], target, answer_time))
  local place = db.urow(fmt([[
  SELECT COUNT(silver_time)
  FROM user_puzzle
  WHERE puzzle = ?
    AND %s_time <= ?
  ]], target), puzzle, answer_time)
  wrt(fmt([[
  <p>You placed %d</p>
  ]], place))
else
  return ServeError(400)
end

wrt(fmt([[<p>Go back to <a href="/%s">the puzzle</a></p>]], puzzle))

html.page_end()
