require('tiles')
require('love')

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setBackgroundColor(0, 0, 0)

  -- Monogram font
  -- https://datagoblin.itch.io/monogram
  local font = love.graphics.newFont('assets/monogram.ttf', 40)
  love.graphics.setFont(font)

  -- Music by DOS-88
  -- https://www.youtube.com/user/AntiMulletpunk
  _G.bg_music = love.audio.newSource('assets/Billy\'s Sacrifice.mp3', 'static')
  bg_music:setVolume(0)
  bg_music:play()

  _G.grid = {
    x_count = 10,
    y_count = 18
  }

  _G.window = {
    w = love.graphics.getWidth(),
    h = love.graphics.getHeight(),
  }

  -- Calculate offsets and block size
  _G.x_offset = window.w / 3

  local x_block_size = x_offset / grid.x_count
  local y_block_size = window.h / grid.y_count
  _G.block_size = math.floor(math.min(x_block_size, y_block_size))

  _G.y_offset = (window.h - block_size * grid.y_count) / 2

  -- Background
  _G.star_size = math.floor(block_size / 10)
  _G.star_max_depth = 50
  _G.star_min_depth = 15
  local total_stars = math.floor((window.w + window.h) / 16)
  _G.stars = {}
  for i = 0, total_stars do
    table.insert(stars, {
      love.math.random(window.w),                      -- x
      love.math.random(window.h),                      -- y
      love.math.random(star_min_depth, star_max_depth) -- z
    })
  end

  _G.state = {
    tile = love.math.random(#tiles),
    rotation = 1,
    pos_x = 0,
    pos_y = 0,
    timer = 0,
    camera_y = 0,
    camera_speed = 10,
    score = 0
  }

  function _G.update_score(n)
    local scores = { 40, 100, 300, 1200 }
    state.score = state.score + scores[n]
  end

  function _G.can_move(pos_x, pos_y, r)
    for y = 1, 4 do
      for x = 1, 4 do
        local test_x = pos_x + x
        local test_y = pos_y + y

        if tiles[state.tile][r][y][x] ~= ' '
            and (
              (test_x) < 1 or              -- Left
              (test_x) > grid.x_count or   -- Right
              (test_y) > grid.y_count or   -- Bottom
              inert[test_y][test_x] ~= ' ' -- Fixed blocks
            ) then
          return false
        end
      end
    end
    return true
  end

  function _G.new_sequence()
    _G.sequence = {}
    for tile_index = 1, #tiles do
      local pos = love.math.random(#sequence + 1)
      table.insert(sequence, pos, tile_index)
    end
  end

  function _G.reset_tile()
    state.tile = table.remove(sequence)
    state.rotation = 1
    state.pos_x = (grid.x_count - 4) / 2
    state.pos_y = -1

    if #sequence == 0 then
      new_sequence()
    end
  end

  function _G.reset()
    --
    _G.inert = {}
    for y = 1, grid.y_count do
      inert[y] = {}
      for x = 1, grid.x_count do
        inert[y][x] = ' '
      end
    end

    new_sequence()
    reset_tile()

    state.timer = 0
  end

  reset()
end

function love.keypressed(k)
  if k == "escape" then
    love.event.push('quit')
  end

  -- Move
  if k == 'a' then -- Left
    local new_x = state.pos_x - 1
    if can_move(new_x, state.pos_y, state.rotation) then
      state.pos_x = new_x
    end
  elseif k == 'd' then -- Right
    local new_x = state.pos_x + 1
    if can_move(new_x, state.pos_y, state.rotation) then
      state.pos_x = new_x
    end
  elseif k == 's' then -- Drop
    while can_move(state.pos_x, state.pos_y + 1, state.rotation) do
      state.pos_y = state.pos_y + 1
      state.timer = 0.5
    end
  end

  -- Rotate
  if k == "x" then
    local new_rotation = state.rotation + 1
    if new_rotation > #tiles[state.tile] then
      new_rotation = 1
    end

    if can_move(state.pos_x, state.pos_y, new_rotation) then
      state.rotation = new_rotation
    end
  elseif k == "z" then
    local new_rotation = state.rotation - 1
    if new_rotation < 1 then
      new_rotation = #tiles[state.tile]
    end

    if can_move(state.pos_x, state.pos_y, new_rotation) then
      state.rotation = new_rotation
    end
  end

  -- Music
  if k == "m" then
    if bg_music:getVolume() > 0 then
      bg_music:setVolume(0)
    else
      bg_music:setVolume(0.2)
    end
  elseif k == "left" then
    bg_music:setVolume(math.min(bg_music:getVolume() - .2, 1))
  elseif k == "right" then
    bg_music:setVolume(math.min(bg_music:getVolume() + .2, 1))
  end
end

function love.update(dt)
  state.camera_y = state.camera_y + state.camera_speed * dt
  state.timer = state.timer + dt

  if not can_move(state.pos_x, state.pos_y, state.rotation) then
    reset()
  end

  if state.timer >= 0.5 then
    state.timer = 0
    local new_y = state.pos_y + 1
    if can_move(state.pos_x, new_y, state.rotation) then
      state.pos_y = new_y
    else
      -- Add to fixed table
      for y = 1, 4 do
        for x = 1, 4 do
          local block = tiles[state.tile][state.rotation][y][x]
          if block ~= ' ' then
            inert[state.pos_y + y][state.pos_x + x] = block
          end
        end
      end

      -- Complete rows
      local total_complete = 0
      for y = 1, grid.y_count do
        local complete = true
        for x = 1, grid.x_count do
          if inert[y][x] == ' ' then
            complete = false
            break
          end
        end

        if complete then
          total_complete = total_complete + 1
          for ry = y, 2, -1 do
            for rx = 1, grid.x_count do
              inert[ry][rx] = inert[ry - 1][rx]
            end
          end

          for rx = 1, grid.x_count do
            inert[1][rx] = ' '
          end
        end
      end

      if total_complete > 0 then
        -- Not sure if it's possible to complete
        -- more than 4 lines in a row, but just in case
        update_score(math.min(total_complete, 4)) --
        total_complete = 0
      end

      reset_tile()
    end
  end
end

function love.draw()
  local function rgb(r, g, b)
    return {
      r / 255,
      g / 255,
      b / 255,
    }
  end

  local function draw_block(block, x, y, grid)
    grid = grid or false
    -- https://flatuicolors.com/palette/ca
    local colors = {
      [' '] = rgb(26, 26, 26),
      i = rgb(72, 219, 251),
      j = rgb(255, 107, 107),
      l = rgb(255, 159, 243),
      o = rgb(95, 39, 205),
      s = rgb(0, 210, 211),
      t = rgb(29, 209, 161),
      z = rgb(52, 31, 151),
    }
    -- Ignore empty blocks if not in grid
    if block == ' ' and not grid then
      return
    end

    local color = colors[block]
    local block_draw_size = block_size - 1

    love.graphics.push()
    love.graphics.setColor(color)
    love.graphics.rectangle(
      'fill',
      (x - 1) * block_size + x_offset,
      (y - 1) * block_size + y_offset,
      block_draw_size,
      block_draw_size
    )
    love.graphics.pop()
  end

  -- Background
  love.graphics.push()
  love.graphics.setColor(1, 1, 1)
  for i = 1, #stars do
    local proj = stars[i][3] / star_max_depth
    local star_proj_size = star_size / proj
    love.graphics.rectangle('fill',
      stars[i][1],
      ((stars[i][2] + state.camera_y) / proj + star_size / 2) %
      (window.h + star_size) - star_size / 2, -- math to wrap around top
      star_proj_size,
      star_proj_size
    )
  end
  love.graphics.pop()

  -- Grid
  for y = 1, grid.y_count do
    for x = 1, grid.x_count do
      draw_block(inert[y][x], x, y, true)
    end
  end
  -- Tile
  for y = 1, 4 do
    for x = 1, 4 do
      local block = tiles[state.tile][state.rotation][y][x]
      draw_block(block, x + state.pos_x, y + state.pos_y)
    end
  end

  -- UI --
  -- Volume bar
  love.graphics.push()
  love.graphics.setColor(1, 1, 1)
  local volume_w = block_size / 4
  for i = 1, bg_music:getVolume() * 10 do
    love.graphics.rectangle('fill', (i - 1) * (volume_w + 2), 0, volume_w, block_size)
  end
  love.graphics.pop()

  local x_col_offset = 2
  -- Score
  love.graphics.push()
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(
    "SCORE",
    block_size * (grid.x_count + x_col_offset) + x_offset,
    y_offset + block_size * 3
  )
  love.graphics.print(
    string.format("%d", state.score),
    block_size * (grid.x_count + x_col_offset) + x_offset,
    y_offset + block_size * 4
  )
  -- Next tile
  love.graphics.print(
    "NEXT",
    block_size * (grid.x_count + x_col_offset) + x_offset,
    y_offset + block_size * 8
  )
  love.graphics.pop()
  for y = 1, 4 do
    for x = 1, 4 do
      local block = tiles[sequence[#sequence]][1][y][x]
      if block ~= ' ' then
        draw_block(block, x + grid.x_count + x_col_offset, y + 9)
      end
    end
  end
end
