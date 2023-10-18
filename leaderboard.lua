html.leaderboard_begin()

html("<p>This leaderboard gets updated once every %d seconds</p>",
config.LEADERBOARD_INTERVAL)
html[[<ol>]]
for user_id, name, link, anon, score in db.urows[[
  SELECT user_id, name, link, anonymous, score
  FROM leaderboard
  INNER JOIN user ON user_id = user.rowid
  ORDER BY score DESC
  ]] do
  html[[<li>]]
  html(tostring(score) .. " ")
  html.user(user_id, anon~=0, name, link)
  html[[</li>]]
end
html[[</ol>]]

html.page_end()
