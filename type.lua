setmetatable(_G, { __index = function(t, k) error("unbound global " .. k) end })

__TYCONS = { }

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

function isEmpty(t)
    for _,_ in pairs(t) do
        return false
    end
    return true
end

function __checkType(val, ty)
  if not (__isPolyType(ty)) then
    assert(val._type == ty, tostring(val) .. " does not have ty " .. tostring(ty))
  end
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

function __mkType(name, vars)
  local tycon = {name = name, vars = vars}
  __TYCONS[name] = {_tycon = tycon, _vars = vars, _cons = {}}

  if isEmpty(vars) then
    _G[name] = tycon
  else
    _G[name] = function(args)
      assert(#args == #vars, "wrong arity for ty constructor " .. name)
      local ty = {_tycon = tycon, _args = args}
      __freeze("", ty,
        { __eq = __eqTy
        , __tostring = function(t)
            return name .. " " .. table.concat(map(tostring, t._args))
          end})
      return ty
    end
  end

  __freeze(name .. " " .. table.concat(vars, " "), tycon)
  return tycon
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

function __eqTy(v1, v2)
  if v1._tycon ~= v2._tycon then return false end
  if #v1._args ~= #v2._args then return false end
  for k, v in pairs(v1._args) do
    if v1[k] ~= v2[k] then return false end
  end
  return true
end

function __eqVal(v1, v2)
  if v1._type ~= v2._type then return false end
  if v1._con ~= v2._con then return false end
  for k, v in pairs(v1._con._fields) do
    if v1[k] ~= v2[k] then return false end
  end
  return true
end


function __mkCon(name, fields, typename)
  ty = _G[typename]
  local con = {_type = ty, _fields = fields}
  for k, v in pairs(fields) do
    con[k] = { fieldName = k, fieldType = v }
  end

  if isEmpty(fields) then
    con._type = __TYCONS[typename]._tycon
    _G[name] = con
  else
    _G[name] = function(args)
      local val = {_con = con}
      local insts = {}
      for field_name, field_type in pairs(fields) do
        val[field_name] = args[field_name]
        if __isPolyType(field_type) then
          insts[field_type] = args[field_name]._type
        end
      end
      -- TODO(sandy): check that all variables are the same
      -- print(__showTable(insts))
      for field_name, field_type in pairs(fields) do
        __checkType(args[field_name], field_type)
      end
      val._type = __instantiate(typename, ty, insts)
      __freeze(name .. " " .. __showTable(val, __external), val, {__eq = __eqVal})
      return val
    end
  end

  __freeze(name, con)
  table.insert(__getTypeCons(__TYCONS[typename]._tycon), con)
  return con
end

function __withoutMetatable(t, f)
  mt = getmetatable(t)
  setmetatable(t, {})
  t = f(t)
  setmetatable(t, mt)
  return t
end

function __instantiate(typename, ty, insts)
  vars = __TYCONS[typename]._vars
  args = {}
  for i, v in pairs(vars) do
    if insts[v] ~= nil then
      args[i] = insts[v]
    else
      args[i] = vars[i]
    end
  end
  return ty(args)
end

function __isPolyType(ty)
  return type(ty) == "string"
end

function __getTypeCons(ty)
  return __TYCONS[ty.name]._cons
end

function __isNullaryTyCon(ty)
  return type(ty) == "table"
end

function data(name, vars, cons)
  local ty = __mkType(name, vars)

  for con_name, con_fields in pairs(cons) do
    __mkCon(con_name, con_fields, name)
  end

  return ty
end

data("Bool", {}, {True = {}, False = {}})

data("Maybe", {"a"}, {Just = { fromJust = "a" }, Nothing = {}})

print(Just({fromJust = False}) == Just({fromJust = True}))

