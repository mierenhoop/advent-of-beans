html.page_begin()
wrt[[<ul>]]
for name, time_start in db.urows[[
  SELECT name, time_start
  FROM puzzle ORDER BY time_start
  ]] do
  wrt"<li>"
  if GetTime() > time_start then
    wrt(fmt([[<a href="/%s">%s</a>]],
    esc(name), esc(name)))
  else
    wrt(esc(name))
  end
  wrt"</li>"
end
wrt[[</ul>]]
html.page_end()
