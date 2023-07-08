local db = require"db"
local html = require"html"

local wrt, fmt = Write, string.format

html.page_begin()

local puzzle_id = tonumber(GetParam("puzzle"))

wrt"<p>Per day:"
for id, name in db.urows"SELECT id, name FROM puzzle ORDER BY time_start" do
  name = EscapeHtml(name)
  if id == puzzle_id then name = "<strong>"..name.."</strong>" end
  wrt(fmt([[ <a href="/leaderboard.lua?puzzle=%s">%s</a>]], id, name))
end
wrt"</p>"

local function dayleaderboard(star)
  wrt[[<ol>]]
  for name, link, time in db.urows(string.gsub([[
    SELECT name, link, STAR_time
    FROM user_puzzle
    INNER JOIN user ON user_puzzle.user_id = user.id
    WHERE puzzle_id = ?
      AND STAR_time IS NOT NULL
    ORDER BY STAR_time ASC
    LIMIT 100
    ]], "STAR", star), puzzle_id) do
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

if puzzle_id then
  wrt"<p>First hundred users to get both stars.</p>"
  dayleaderboard"gold"
  wrt"<p>First hundred users to get a silver star.</p>"
  dayleaderboard"silver"
else
  wrt"<p>This leaderboard gets updated once every 10 seconds</p>"
  wrt[[<ol>]]
  for name, link, score in db.urows[[
    SELECT name, link, score
    FROM leaderboard
    INNER JOIN user ON user_id = id
    ORDER BY score DESC
    ]] do
    wrt[[<li>]]
    name = EscapeHtml(name)
    local host = link and ParseUrl(link).host
    wrt(tostring(score) .. " ")
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



html.page_end()
