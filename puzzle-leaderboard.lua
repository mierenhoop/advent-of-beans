html.leaderboard_begin()

local function dayleaderboard(star)
  wrt[[<ol>]]
  for user_id, name, link, anon, time in db.urows([[
    SELECT user_id, name, link, anonymous, time
    FROM achievement
    INNER JOIN user ON achievement.user_id = user.rowid
    WHERE puzzle = ?
      AND type = ?
    ORDER BY achievement.time, achievement.rowid
    LIMIT 100
    ]], puzzle, star) do
    wrt[[<li>]]
    wrt(fmt("%.2f ", time))
    html.user(user_id, anon~=0, name, link)
    wrt[[</li>]]
  end
  wrt[[</ol>]]
end

wrt"<p>First hundred users to get both stars.</p>"
dayleaderboard"gold"
wrt"<p>First hundred users to get a silver star.</p>"
dayleaderboard"silver"

html.page_end()
