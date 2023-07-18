html.leaderboard_begin()

--TODO: anonymous

wrt"<p>This leaderboard gets updated once every 10 seconds</p>"
wrt[[<ol>]]
for name, link, anon, score in db.urows[[
  SELECT name, link, anonymous, score
  FROM leaderboard
  INNER JOIN user ON user_id = user.rowid
  ORDER BY score DESC
  ]] do
  wrt[[<li>]]
  wrt(tostring(score) .. " ")
  html.user(anon~=0, name, link)
  wrt[[</li>]]
end
wrt[[</ol>]]

html.page_end()
