typ = require('type')
require('utils')
require('prelude')


local function flatten(t)
  local ret = {}
  for _, v in ipairs(t) do
    if type(v) == 'table' and v._type == nil then
      for _, fv in ipairs((v)) do
        ret[#ret + 1] = fv
      end
    else
      ret[#ret + 1] = v
    end
  end
  return ret
end

local function wrapCheckRes(func, ty_res)
  return function(x)
    local res = func(x)
    typ.checkType(x, ty_res)
    return res
  end
end

local function curry(func, types, ty_res, num_args)
  num_args = num_args or debug.getinfo(func, "u").nparams
  if num_args < 2 then
    return wrapCheckRes(func, ty_res)
  end

  local function helper(argtrace, types, n)
    if n < 1 then
      local res = func(table.unpack(flatten(argtrace)))
      typ.checkType(res, ty_res)
      return res
    else
      return function (...)
        for i, a in ipairs({...}) do
          typ.checkType(a, types[1])
          table.remove(types, 1)
        end

        return helper({argtrace, ...}, types, n - select("#", ...))
      end
    end
  end
  return helper({}, types, num_args)
end

function fun(ty_args, ty_res, fn)
  return curry(fn, ty_args, ty_res)
end

orH = fun({Bool, Bool}, Bool, function(x, y)
  if x == True then
    return True
  else
    return y
  end
end)

print(orH(False, False))


