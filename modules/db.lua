local lsqlite3 = require"lsqlite3"

local db = {}

function db:close()
  self._db:close()
end

local function open(path)
  local _db = assert(lsqlite3.open(path))
  local self = setmetatable({_db = _db}, { __index = db, __close = db.close})
  _db:busy_timeout(1000)

  if _db:exec[[
    PRAGMA journal_mode=wal;
    PRAGMA synchronous=normal;
    ]] ~= lsqlite3.OK then
    local err = _db:errmsg()
    _db:close()
    error(err)
  end
  return self
end

function db:prepare(sql, ...)
  local stmt = self._db:prepare(sql)
  if not stmt then error(self._db:errmsg()) end
  if stmt:bind_values(...) ~= lsqlite3.OK then
    error(self._db:errmsg())
  end
  return stmt
end

function db:exec(sql)
  local ret = self._db:exec(sql)
  if ret ~= lsqlite3.OK then error(self._db:errmsg()) end
end

function db:urow(sql, ...)
  local stmt = self:prepare(sql, ...)
  local rows = table.pack(stmt:urows()(stmt))
  if stmt:finalize() ~= lsqlite3.OK then
    error(self._db:errmsg())
  end
  return table.unpack(rows)
end

function db:urows(sql, ...)
  local stmt = self:prepare(sql, ...)
  local closer = setmetatable({}, {
    __close = function()
      if stmt:finalize() ~= lsqlite3.OK then
        error(self._db:errmsg())
      end
    end
  })
  return stmt:urows(), stmt, nil, closer
end

-- TODO: maybe use savepoint like in https://github.com/pkulchenko/fullmoon/blob/2136239e1fb565db79caebca744ce549c97d7487/fullmoon.lua#L752-L752
function db.transaction(f)
  self:exec"BEGIN TRANSACTION;"

  local ok, err = pcall(f)
  if not ok then
    self:exec"ROLLBACK;"
    error(err)
  end

  self:exec"COMMIT;"
end

return open
