html.page_begin()

local norm = tonumber(db.urow[[
SELECT MAX(silver_count)
FROM (SELECT puzzle, COUNT(silver_time) silver_count
  FROM user_puzzle
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
  SELECT puzzle, COUNT(gold_time), COUNT(silver_time)
  FROM user_puzzle
  INNER JOIN puzzle ON puzzle.name = user_puzzle.puzzle
  GROUP BY puzzle
  ORDER BY time_start
  ]] do

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