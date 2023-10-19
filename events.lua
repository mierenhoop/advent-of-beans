html.page_begin()

html[[<ul>]]
for event_id, event_name in db.urows[[
  SELECT rowid, name
  FROM event
  ORDER BY time DESC
  ]] do
  html[[<li>]]
  local stars = db.urow([[
  SELECT COUNT(*)
  FROM achievement
  INNER JOIN puzzle ON puzzle.rowid = puzzle_id
  WHERE user_id = ?
  AND event_id = ?
  ]], db.user_id, event_id)
  html([[<p><a href="%s">%s</a>: <strong>%d</strong> %s</p>]],
  EscapeHtml(html.link(nil, event_name)), EscapeHtml(event_name), stars, stars == 1 and "star" or "stars")
  html[[</li>]]
end
html[[</ul>]]

html.page_end()
