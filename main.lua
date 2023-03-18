Object = require "lib.classic"

CHUNK_SIZE = 8
CHUNK_HEIGHT = 32

local Matrix = require "matrix"
local Player = require "player"

_debug = {}
function debug(...)
  local vars = {...}
  local str = ""
  for i = 1, #vars do
    str = str .. tostring(vars[i]) .. " "
  end
  table.insert(_debug, str)
end

function love.mousemoved(x, y, dx, dy)
  player:updateDirection(dx, dy)
end

function love.load()
  love.graphics.setDepthMode("lequal", true)
  love.graphics.setMeshCullMode("back")

  love.mouse.setRelativeMode(true)
  love.graphics.setDefaultFilter("nearest", "nearest")

  tileset = love.graphics.newImage("tileset.png")

  love.graphics.setBackgroundColor(0.65, 0.6, 0.95)

  local World = require "world"

  world = World()

  player = Player(world)
end

function love.update(dt)
  _debug = {}
  player:update(dt)
end

function love.draw()
  player:draw()

  local w, h = love.graphics.getDimensions()
  love.graphics.circle("fill", w / 2, h / 2, 2)

  debug("FPS:", love.timer.getFPS())

  for i, v in ipairs(_debug) do
    love.graphics.print(v, 10, 10 + (i - 1) * 20)
  end
end
