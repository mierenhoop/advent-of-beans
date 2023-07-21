html.leaderboard_begin()

local function dayleaderboard(star)
  wrt[[<ol>]]
  for user_id, name, link, anon, time in db.urows(string.gsub([[
    SELECT user_id, name, link, anonymous, STAR_time
    FROM user_puzzle
    INNER JOIN user ON user_puzzle.user_id = user.rowid
    WHERE puzzle = ?
      AND STAR_time IS NOT NULL
    ORDER BY STAR_time ASC, user_id
    LIMIT 100
    ]], "STAR", star), puzzle) do
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
