html.page_begin()

local norm = tonumber(db.urow[[
SELECT MAX(silver_count)
FROM (SELECT puzzle_id, COUNT(nullif(type = 'silver', 0)) silver_count
  FROM achievement
  GROUP BY puzzle_id);
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
for puzzle_id, gold, silver in db.urows[[
  SELECT puzzle_id, COUNT(nullif(type = 'gold', 0)), COUNT(nullif(type = 'silver', 0))
  FROM achievement
  INNER JOIN puzzle ON puzzle.rowid = achievement.puzzle_id
  WHERE time_start <= unixepoch()
  GROUP BY puzzle_id
  ORDER BY time_start
  ]] do

  local puzzle_name = db.urow("SELECT name FROM puzzle WHERE rowid = ?", puzzle_id)

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
  ]], puzzle_name, puzzle_name, gold, silver, stars))
end
wrt"</table>"


html.page_end()
