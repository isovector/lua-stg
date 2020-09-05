setmetatable(_G, { __index = function(t, k) error("unbound global " .. k) end })

__TYPES = { }

function isEmpty(t)
    for _,_ in pairs(t) do
        return false
    end
    return true
end

function __checkType(val, type)
  assert(val._type == type, tostring(val) .. " does not have type " .. tostring(type))
end

function __freeze(name, table, also)
  local t =
    { __tostring = function() return name end
    , __newindex = function(t, _, _) error("attempt to set a key on " .. tostring(t)) end
    }
  if also ~= nil then
    for k, v in pairs(also) do
      t[k] = v
    end
  end

  setmetatable(table, t)
end

function __mkType(name)
  local type = {name = name}
  __TYPES[name] = {type = type, cons = {}}

  _G[name] = type
  __freeze("type:" .. name, type)
  return type
end

function id(x) return x end

function __external(s)
  return s:sub(1,1) ~= "_"
end

function __showTable(t, f)
  if f == nil then
    f = function() return true end
  end

  local res = ""
  for k, v in pairs(t) do
    if f(tostring(k)) then
      res = res .. ", " .. k .. "=" .. tostring(v)
    end
  end
  return "{" .. res:sub(3) .. "}"
end

function __eqVal(v1, v2)
  if v1._type ~= v2._type then return false end
  if v1._con ~= v2._con then return false end
  for k, v in pairs(v1._con._fields) do
    if v1[k] ~= v2[k] then return false end
  end
  return true
end


function __mkCon(name, fields, type)
  local con = {_type = type, _fields = fields}
  for k, v in pairs(fields) do
    con[k] = { fieldName = k, fieldType = v }
  end

  if isEmpty(fields) then
    _G[name] = con
  else
    _G[name] = function(quarks)
      local val = {_type = type, _con = con}
      for field_name, field_type in pairs(fields) do
        __checkType(quarks[field_name], field_type)
        val[field_name] = quarks[field_name]
      end
      __freeze(name .. " " .. __showTable(val, __external), val, {__eq = __eqVal})
      return val
    end
  end

  __freeze(name, con)
  table.insert(__getTypeCons(type), con)
  return con
end

function __getTypeCons(type)
  return __TYPES[type.name].cons
end

function data(name, cons)
  local type = __mkType(name)

  for con_name, con_fields in pairs(cons) do
    __mkCon(con_name, con_fields, type)
  end

  return type
end

data("Bool", {True = {}, False = {}})

data("Maybe", {Just = { fromJust = Bool }, Nothing = {}})

print(Just({fromJust = Nothing}))

