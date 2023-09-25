#!/usr/bin/env lua5.4

local db <close> = require"db"("/tmp/test.db")

db:exec[[
CREATE TABLE IF NOT EXISTS t(a, b);
]]

for i = 1, 10 do
  db:urow("INSERT INTO t VALUES (?, ?)", i, i * 2)
end

for a, b  in db:urows"SELECT a, b FROM t" do
  print(a, b)
end
