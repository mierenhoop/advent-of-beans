local db = require "db"
local html = require "html"
local wrt, fmt, esc = Write, string.format, EscapeHtml

html.page_begin()
wrt[[<ul>]]
for name, id, time_start in db.urows[[
  SELECT name, id, time_start
  FROM puzzle ORDER BY time_start
  ]] do
  wrt"<li>"
  if GetTime() > time_start then
    wrt(fmt([[<a href="/puzzle.lua?id=%d">%s</a>]],
    esc(EscapeSegment(id)), esc(name)))
  else
    wrt(esc(name))
  end
  wrt"</li>"
end
wrt[[</ul>]]
html.page_end()
