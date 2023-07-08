local db = require "db"

local wrt, fmt, esc = Write, string.format, EscapeHtml

local html = {}

--function html.maybelink(cont, link, options)
--  cont = esc(cont)
--  options = options and (" " .. options) or ("")
--  if link then
--    wrt(fmt([[<a href="%s"%s>%s</a>]], esc(link), options, cont))
--  else
--    wrt(fmt("<span%s>%s</span>", options, cont))
--  end
--end

function html.page_begin(title)
  wrt[[<!DOCTYPE html>]]
  wrt[[<html lang="en">]]
  wrt[[<meta charset="UTF-8">]]
  wrt[[<link rel="stylesheet" href="/style.css">]]
  wrt[[<nav>]]
  wrt[[<a href="/">Advent</a>]]
  wrt" | "
  wrt[[<a href="/about.lua">About</a>]]
  wrt" | "
  wrt[[<a href="/leaderboard.lua">Leaderboard</a>]]
  wrt" | "
  local user_id = db.get_session_user_id()
  local name
  if user_id then
    name = db.urow("SELECT name FROM user WHERE id = ?", user_id)
  end
  wrt(fmt([[<a href="/profile.lua">%s</a>]], name and EscapeHtml(name) or "Login"))

  --html.maybelink("Leaderboard", p ~= "/leaderboard.lua" and "/leaderboard.lua")
  wrt[[</nav>]]
  wrt"<main>"
end

function html.page_end()
  wrt"</main>"
  wrt[[</html>]]
end

return html
