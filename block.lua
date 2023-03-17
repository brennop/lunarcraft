local Object = require "lib.classic"
local Block = Object:extend()

local Vector = require "vector"
local Matrix = require "matrix"

local cube = require "cube"

function Block:new()
  self.mesh = cube({
    { 3, 30 },
    { 3, 16 },
    { 3, 30 },
    { 3, 31 },
    { 3, 30 },
    { 3, 30 }
  })

  self.position = Vector(0, 0, 0)

  self.model = Matrix()

  self:updateModel()
end

-- we are just interested in the translation for now
function Block:updateModel()
  local tx, ty, tz = self.position:unpack()

  -- translate
  self.model[4] = tx
  self.model[8] = ty
  self.model[12] = tz
end

function Block:draw()
  shader:send("modelMatrix", self.model)
  love.graphics.draw(self.mesh)
end

return Block
