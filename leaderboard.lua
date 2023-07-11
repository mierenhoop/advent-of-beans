html.leaderboard_begin()

wrt"<p>This leaderboard gets updated once every 10 seconds</p>"
wrt[[<ol>]]
for name, link, score in db.urows[[
  SELECT name, link, score
  FROM leaderboard
  INNER JOIN user ON user_id = user.rowid
  ORDER BY score DESC
  ]] do
  wrt[[<li>]]
  name = esc(name)
  local host = link and ParseUrl(link).host
  wrt(tostring(score) .. " ")
  if link and host then
    wrt(fmt([[<a href="%s">%s</a><sub>[%s]</sub>]],
    esc(link), name, esc(host)))
  else
    wrt(name)
  end
  wrt[[</li>]]
end
wrt[[</ol>]]

html.page_end()
