_G.love = require('love')
function love.load()
  love.graphics.setBackgroundColor(0, 0, 0)

  _G.grid = {
    x_count = 10,
    y_count = 18
  }
end

function love.keypressed(k)
  if k == "escape" then
    love.event.push('quit')
  end
end

function love.update(dt)
end

function love.draw()
  for y = 1, grid.y_count do
    for x = 1, grid.x_count do
      love.graphics.setColor(0.5, 0.5, 0.5)
      local block_size = 20
      local block_draw_size = block_size - 1
      love.graphics.rectangle(
        'fill',
        (x - 1) * block_size,
        (y - 1) * block_size,
        block_draw_size,
        block_draw_size
      )
    end
  end
end
