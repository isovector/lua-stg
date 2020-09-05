function isExternalField(s)
  return s:sub(1,1) ~= "_"
end

function showT(t, f)
  if f == nil then
    f = function() return true end
  end

  local res = ""
  for k, v in pairs(t) do
    if f(tostring(k)) then
      res = res .. ", " .. k .. "="
      if type(v) == "table" then
        res = res .. showT(v)
      else
        res = res .. tostring(v)
      end
    end
  end
  return "{" .. res:sub(3) .. "}"
end

function dbg(t)
  print(showT(t))
end

function isEmpty(t)
    for _,_ in pairs(t) do
        return false
    end
    return true
end

function table.clone(org)
  return {table.unpack(org)}
end

function map(f, tbl)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = f(v)
    end
    return t
end

