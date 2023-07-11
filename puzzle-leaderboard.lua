html.leaderboard_begin()

local function dayleaderboard(star)
  wrt[[<ol>]]
  for name, link, time in db.urows(string.gsub([[
    SELECT name, link, STAR_time
    FROM user_puzzle
    INNER JOIN user ON user_puzzle.user_id = user.rowid
    WHERE puzzle = ?
      AND STAR_time IS NOT NULL
    ORDER BY STAR_time ASC
    LIMIT 100
    ]], "STAR", star), puzzle) do
    wrt[[<li>]]
    name = EscapeHtml(name)
    local host = link and ParseUrl(link).host
    wrt(fmt("%.2f ", time))
    if link and host then
      wrt(fmt([[<a href="%s">%s</a><sub>[%s]</sub>]],
      EscapeHtml(link), name, EscapeHtml(host)))
    else
      wrt(name)
    end
    wrt[[</li>]]
  end
  wrt[[</ol>]]
end

wrt"<p>First hundred users to get both stars.</p>"
dayleaderboard"gold"
wrt"<p>First hundred users to get a silver star.</p>"
dayleaderboard"silver"

html.page_end()
