require('type')

function __showTable(t, f)
  if f == nil then
    f = function() return true end
  end

  local res = ""
  for k, v in pairs(t) do
    if f(tostring(k)) then
      res = res .. ", " .. k .. "="
      if type(v) == "table" then
        res = res .. __showTable(v)
      else
        res = res .. tostring(v)
      end
    end
  end
  return "{" .. res:sub(3) .. "}"
end

function dbg(t)
  print(__showTable(t))
end


data("Maybe", {"a"}, {Just = { fromJust = "a" }, Nothing = {}})
data("Bool", {}, {True = {}, False = {}})

print(Just({fromJust = True}) == Just({fromJust = True}))

