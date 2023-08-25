_G.love = require('love')
function love.load()
  love.graphics.setBackgroundColor(0, 0, 0)

  _G.grid = {
    x_count = 10,
    y_count = 18
  }

  _G.window = {
    w = love.graphics.getWidth(),
    h = love.graphics.getHeight(),
  }

  _G.x_offset = window.w / 3

  local x_block_size = x_offset / grid.x_count
  local y_block_size = window.h / grid.y_count
  _G.block_size = math.floor(math.min(x_block_size, y_block_size))

  _G.y_offset = (window.h - block_size * grid.y_count) / 2

  _G.star_size = math.floor(block_size / 10)
  local total_stars = math.floor((window.w + window.h) / 16)
  _G.stars = {}
  for i = 0, total_stars do
    table.insert(stars, { math.random(window.w), math.random(window.h) })
  end
end

function love.keypressed(k)
  if k == "escape" then
    love.event.push('quit')
  end
end

function love.update(dt)
  math.random()
end

function love.draw()
  -- Draw background
  love.graphics.push()
  love.graphics.setColor(1, 1, 1)
  for i = 1, #stars do
    love.graphics.rectangle('fill', stars[i][1], stars[i][2], star_size, star_size)
  end
  love.graphics.pop()

  -- Draw grid
  for y = 1, grid.y_count do
    for x = 1, grid.x_count do
      love.graphics.setColor(0.5, 0.5, 0.5)
      local block_draw_size = block_size - 1
      love.graphics.rectangle(
        'fill',
        (x - 1) * block_size + window.w / 3,
        (y - 1) * block_size + y_offset,
        block_draw_size,
        block_draw_size
      )
    end
  end
end
