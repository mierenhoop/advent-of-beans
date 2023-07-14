html.page_begin()

local norm = tonumber(db.urow[[
SELECT MAX(silver_count)
FROM (SELECT puzzle, COUNT(silver_time) silver_count
  FROM user_puzzle
  GROUP BY puzzle);
]] or math.huge)

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
for puzzle in db.urows[[
  SELECT name
  FROM puzzle
  ORDER BY time_start ASC
  ]] do
  local gold, silver = db.urow([[
  SELECT COUNT(gold_time), COUNT(silver_time)
  FROM user_puzzle
  WHERE puzzle = ?
  ]], puzzle)

  local total = math.ceil(silver / norm * maxstars)
  local ngold = math.ceil(gold / norm * maxstars)
  local nsilver = total - ngold

  wrt(fmt([[
  <tr>
  <td><a href="/%s">%s</a></td>
  <td>%d</td>
  <td>%d</td>
  <td>%s</td>
  </a>
  ]], puzzle, puzzle, gold, silver, ("*"):rep(ngold)..("%"):rep(nsilver)))
end
wrt"</table>"


html.page_end()
