html.page_begin()

wrt[[<ul>]]
for event_id, event_name in db.urows[[
  SELECT rowid, name
  FROM event
  ORDER BY time DESC
  ]] do
  wrt[[<li>]]
  local stars = db.urow([[
  SELECT COUNT(*)
  FROM achievement
  INNER JOIN puzzle ON puzzle.rowid = puzzle_id
  WHERE user_id = ?
  AND event_id = ?
  ]], db.user_id, event_id)
  wrt(fmt([[<p>%s: <strong>%d</strong> %s</p>]], EscapeHtml(event_name), stars, stars == 1 and "star" or "stars"))
  wrt[[</li>]]
end
wrt[[</ul>]]

html.page_end()
