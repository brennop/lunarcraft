Object = require "lib.classic"

local Matrix = require "matrix"
local Camera = require "camera"

local camera

_debug = {}
function debug(...)
  local vars = {...}
  local str = ""
  for i = 1, #vars do
    str = str .. tostring(vars[i]) .. " "
  end
  table.insert(_debug, str)
end

local vert = [[
uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
// uniform mat4 modelMatrix;

vec4 position( mat4 transform_projection, vec4 vertexPosition )
{
    return projectionMatrix * viewMatrix * vertexPosition;
}
]]

function love.mousemoved(x, y, dx, dy)
  camera:updateDirection(dx, dy)
end

function love.load()
  love.graphics.setDepthMode("lequal", true)
  love.mouse.setRelativeMode(true)
  love.graphics.setDefaultFilter("nearest", "nearest")

  shader = love.graphics.newShader(vert)

  tileset = love.graphics.newImage("tileset.png")

  local Chunk = require "chunk"

  chunks = {}
  for i = -2, 2 do
    for j = -2, 2 do
      table.insert(chunks, Chunk(i, -2, j))
    end
  end

  camera = Camera()
end

function love.update(dt)
  _debug = {}
  camera:update(dt)
end

function love.draw()
  love.graphics.setShader(shader)

  shader:send("viewMatrix", camera.view)
  shader:send("projectionMatrix", camera.projection)

  for _, chunk in ipairs(chunks) do
    chunk:draw()
  end

  love.graphics.setShader()

  debug("FPS:", love.timer.getFPS())

  for i, v in ipairs(_debug) do
    love.graphics.print(v, 10, 10 + (i - 1) * 20)
  end
end
