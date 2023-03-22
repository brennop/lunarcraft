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

function Matrix:__tostring()
  return string.format("%.2f %.2f %.2f %.2f\n%.2f %.2f %.2f %.2f\n%.2f %.2f %.2f %.2f\n%.2f %.2f %.2f %.2f",
    self[1], self[2], self[3], self[4],
    self[5], self[6], self[7], self[8],
    self[9], self[10], self[11], self[12],
    self[13], self[14], self[15], self[16])
end

function Matrix:ortho(left, right, bottom, top, near, far)
  self[1],  self[2],  self[3],  self[4]  = 2/(right-left), 0, 0, -1*(right+left)/(right-left)
  self[5],  self[6],  self[7],  self[8]  = 0, 2/(top-bottom), 0, -1*(top+bottom)/(top-bottom)
  self[9],  self[10], self[11], self[12] = 0, 0, -2/(far-near), -(far+near)/(far-near)
  self[13], self[14], self[15], self[16] = 0, 0, 0, 1
end

function Matrix:lookAt(position, target, up)
  local z = (position - target):normalized()
  local x = up:cross(z):normalized()
  local y = z:cross(x)

  self[1],  self[2],  self[3],  self[4]  = x.x, x.y, x.z, -x:dot(position)
  self[5],  self[6],  self[7],  self[8]  = y.x, y.y, y.z, -y:dot(position)
  self[9],  self[10], self[11], self[12] = z.x, z.y, z.z, -z:dot(position)
  self[13], self[14], self[15], self[16] = 0,   0,   0,   1
end                                        

return Matrix
