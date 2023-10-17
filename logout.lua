if db.user_id then
  if db.write_limiter() then return end

  db.urow("DELETE FROM session WHERE user_id = ?", db.user_id)
end

SetStatus(303)
SetCookie(db.cookie_key, "", { expires = 0 })
return SetHeader("Location", "/profile")
