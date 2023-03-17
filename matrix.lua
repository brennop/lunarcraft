local Object = require "lib.classic"

local Matrix = Object:extend()

function Matrix:new()
  self[1],  self[2],  self[3],  self[4]  = 1, 0, 0, 0
  self[5],  self[6],  self[7],  self[8]  = 0, 1, 0, 0
  self[9],  self[10], self[11], self[12] = 0, 0, 1, 0
  self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

function Matrix:set(mat)
  for i = 1, 16 do self[i] = mat[i] end

  return mat
end

return Matrix
