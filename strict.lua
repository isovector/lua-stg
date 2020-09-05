setmetatable(_G,
  { __index = function(t, k) error("unbound global " .. k) end
  , __newindex = function(t, k, v)
      -- print("setting global " .. tostring(k) .. " to " .. tostring(v))
      rawset(t, k, v)
    end
  })

