html.leaderboard_begin()

wrt(fmt("<p>This leaderboard gets updated once every %d seconds</p>",
LEADERBOARD_INTERVAL))
wrt[[<ol>]]
for user_id, name, link, anon, score in db.urows[[
  SELECT user_id, name, link, anonymous, score
  FROM leaderboard
  INNER JOIN user ON user_id = user.rowid
  ORDER BY score DESC
  ]] do
  wrt[[<li>]]
  wrt(tostring(score) .. " ")
  html.user(user_id, anon~=0, name, link)
  wrt[[</li>]]
end
wrt[[</ol>]]

html.page_end()
