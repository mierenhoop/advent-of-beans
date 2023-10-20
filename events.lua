html.page_begin()

local total = 0

html[[<ul>]]
for event_id, event_name in db.urows[[
  SELECT rowid, name
  FROM event
  ORDER BY time DESC
  ]] do
  html[[<li>]]
  html([[<p><a href="%s">%s</a>]], EscapeHtml(html.link(nil, event_name)), EscapeHtml(event_name))
  if db.user_id then
    local stars = db.urow([[
    SELECT COUNT(*)
    FROM achievement
    INNER JOIN puzzle ON puzzle.rowid = puzzle_id
    WHERE user_id = ?
    AND event_id = ?
    ]], db.user_id, event_id)
    total = total + stars
    html([[: <strong>%d</strong> %s</p>]], stars, stars == 1 and "star" or "stars")
  end
  html[[</li>]]
end
html[[</ul>]]

if db.user_id then
  html([[<p>Total stars: %d</p>]], total)
end

html.page_end()
