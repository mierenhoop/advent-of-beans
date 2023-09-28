html.page_begin()

wrt[[<ul>]]
wrt[[<li>]]
local stars = db.urow([[
SELECT COUNT(*)
FROM achievement
WHERE user_id = ?
]], db.get_session_user_id())
wrt(fmt([[<p>[current] <strong>%d</strong> %s</p>]], stars, stars == 1 and "star" or "stars"))
wrt[[</li>]]
wrt[[</ul>]]

html.page_end()
