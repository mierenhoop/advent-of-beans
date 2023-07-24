html.page_begin()

local norm = tonumber(db.urow[[
SELECT MAX(silver_count)
FROM (SELECT puzzle, COUNT(nullif(type = 'silver', 0)) silver_count
  FROM achievement
  GROUP BY puzzle);
]] or math.huge)
if norm == 0 then norm = math.huge end

local maxstars = 20

wrt"<table>"
wrt[[
<tr>
<th>Puzzle</th>
<th>Gold</th>
<th>Silver</th>
<th>Distribution</th>
</tr>
]]
for puzzle, gold, silver in db.urows[[
  SELECT puzzle, COUNT(nullif(type = 'gold', 0)), COUNT(nullif(type = 'silver', 0))
  FROM achievement
  INNER JOIN puzzle ON puzzle.name = achievement.puzzle
  WHERE time_start <= unixepoch()
  GROUP BY puzzle
  ORDER BY time_start
  ]] do

  local total = math.ceil(silver / norm * maxstars)
  local ngold = math.ceil(gold / norm * maxstars)
  local nsilver = total - ngold

  local stars = fmt([[
  <span class="stat-gold">%s</span><span class="stat-silver">%s</span>
  ]], ("*"):rep(ngold), ("*"):rep(nsilver))

  wrt(fmt([[
  <tr>
  <td><a href="/%s">%s</a></td>
  <td>%d</td>
  <td>%d</td>
  <td><code>%s</code></td>
  </a>
  ]], puzzle, puzzle, gold, silver, stars))
end
wrt"</table>"


html.page_end()
