if db.user_id then
  db.urow("DELETE FROM session WHERE user_id = ?", db.user_id)
end

SetStatus(303)
SetCookie(COOKIE_KEY, "", { expires = 0 })
return SetHeader("Location", "/profile")
