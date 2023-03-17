local matrix = require "matrix"
local Camera = require "camera"

local vertices = {
  { -0.5,  0.5, 0.0, 0, 0 },
  { -0.5, -0.5, 0.0, 1, 1 },
  {  0.5, -0.5, 0.0, 0, 1 },
  {  0.5,  0.5, 0.0, 1, 0 },
}

local shader, mesh
local model, view, projection

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

local format = {
    {"VertexPosition", "float", 3},
    {"VertexTexCoord", "float", 2},
}

local vertexShader = [[
uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;

vec4 position( mat4 transform_projection, vec4 vertexPosition )
{
    return projectionMatrix * viewMatrix * modelMatrix * vertexPosition;
}
]]

function love.mousemoved(x, y, dx, dy)
  camera:updateDirection(dx, dy)
end

function love.load()
  love.mouse.setRelativeMode(true)
  love.graphics.setDefaultFilter("nearest", "nearest")

  mesh = love.graphics.newMesh(format, vertices, "triangles")
  shader = love.graphics.newShader(vertexShader)

  camera = Camera()

  model = matrix()
  view = matrix()
  projection = matrix()
end

function love.update(dt)
  _debug = {}
  camera:update(dt)
end

function love.draw()
	local w, h = love.graphics.getDimensions()

	love.graphics.push()
	-- love.graphics.translate(w/2, h/2)

  shader:send("modelMatrix", model)

  shader:send("viewMatrix", camera.view)
  shader:send("projectionMatrix", camera.projection)

  love.graphics.setShader(shader)
  love.graphics.setColor(1,1,1)
  love.graphics.draw(mesh)
  love.graphics.setShader()

  love.graphics.pop()

  for i, v in ipairs(_debug) do
    love.graphics.print(v, 10, 10 + (i - 1) * 20)
  end
end
