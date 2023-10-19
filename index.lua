html.page_begin()
html[[<ul>]]
for name, started in db.urows[[
  SELECT name, time_start <= unixepoch()
  FROM puzzle ORDER BY time_start
  ]] do
  html[[<li>]]
  if started == 1 then
    html([[<a href="%s">%s</a>]], EscapeHtml(html.linkpuzzle(nil, name)), EscapeHtml(name))
    --html([[<a href="/%s">%s</a>]],
    --EscapeHtml(name), EscapeHtml(name))
  else
    html(EscapeHtml(name))
  end
  html[[</li>]]
end
html[[</ul>]]
html.page_end()
