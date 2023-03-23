Object = require "lib.classic"

CHUNK_SIZE = 16
CHUNK_HEIGHT = 32

local Player = require "src.player"

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

function love.mousepressed(x, y, button)
  player:handlePress(x, y, button)
end

function love.keypressed(key)
  if key == "escape" then love.event.quit() end
  if key == "f3" then love.window.setFullscreen(not love.window.getFullscreen()) end
  if key == "f2" then love.graphics.captureScreenshot(os.time() .. ".png") end
  if key == "k" then world:save() end
end

function love.load()
  love.mouse.setRelativeMode(true)
  love.graphics.setDefaultFilter("nearest", "nearest")

  tileset = love.graphics.newImage("tileset.png")

  love.filesystem.setIdentity("lunarcraft")

  love.graphics.setBackgroundColor(0.65, 0.6, 0.95)

  local World = require "src.world"

  world = World:new()

  player = Player(world)
end

function love.update(dt)
  _debug = {}
  player:update(dt)
  world:update(dt)
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
