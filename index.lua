html.page_begin()
wrt[[<ul>]]
for name, started in db.urows[[
  SELECT name, time_start <= unixepoch()
  FROM puzzle ORDER BY time_start
  ]] do
  wrt"<li>"
  if started == 1 then
    wrt(fmt([[<a href="/%s">%s</a>]],
    esc(name), esc(name)))
  else
    wrt(esc(name))
  end
  wrt"</li>"
end
wrt[[</ul>]]
html.page_end()
