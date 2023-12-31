html.leaderboard_begin()

local function dayleaderboard(star)
  html[[<ol>]]
  for user_id, name, link, anon, time in db.urows([[
    SELECT user_id, name, link, anonymous, time
    FROM achievement
    INNER JOIN user ON achievement.user_id = user.rowid
    WHERE puzzle_id = ?
      AND type = ?
    ORDER BY achievement.time, achievement.rowid
    LIMIT 100
    ]], db.puzzle_id, star) do
    html[[<li>]]
    html("%.2f ", time)
    html.user(user_id, anon~=0, name, link)
    html[[</li>]]
  end
  html[[</ol>]]
end

html[[<p>First hundred users to get both stars.</p>]]
dayleaderboard"gold"
html[[<p>First hundred users to get a silver star.</p>]]
dayleaderboard"silver"

html.page_end()
