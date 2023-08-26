require('tiles')
require('love')
_G.flux = require('lib.flux.flux')
local util = require('util')

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setBackgroundColor(0, 0, 0)

  -- Monogram font
  -- https://datagoblin.itch.io/monogram
  _G.font = love.graphics.newFont('assets/monogram.ttf', 40)
  love.graphics.setFont(font)

  -- Music by DOS-88
  -- https://www.youtube.com/user/AntiMulletpunk
  -- SFX by phoenix1291
  -- https://phoenix1291.itch.io/sound-effects-mini-pack1-5
  _G.sfx = {
    bg_music = love.audio.newSource('assets/Billy\'s Sacrifice.mp3', 'static'),
    warp = love.audio.newSource('assets/1up2.ogg', 'static'),
    score = love.audio.newSource('assets/Hit1.ogg', 'static')
  }
  sfx.bg_music:setVolume(0.2)
  sfx.bg_music:setLooping(true)
  sfx.bg_music:play()

  -- Shaders
  _G.shaders = {
    chromatic_aberration = love.graphics.newShader("shaders/chromatic_aberration.frag"),
  }

  _G.state = {
    timer = 0,
    tile = love.math.random(#tiles),
    pos_x = 0,
    pos_y = 0,
    rotation = 1,
    score = 0,
    gravity = 1,

    min_camera_speed = 10,
    max_camera_speed = 500,
    camera_speed = 10,
    camera_y = 0,

    shake_duration = 0,
    shake_wait = 0,
    shake_offset = { x = 0, y = 0 },

    previous_warp = 0,
    warping = false,
    max_warp_duration = 1,
    warp_duration = 0,
    warp_color = { 1, 1, 1 }
  }

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

  -- https://flatuicolors.com/palette/ca
  _G.color_keys = { 'i', 'j', 'l', 'o', 's', 't', 'z' }
  _G.colors = {
    [' '] = util.rgb(26, 26, 26),
    i = util.rgb(72, 219, 251),
    j = util.rgb(255, 107, 107),
    l = util.rgb(255, 159, 243),
    o = util.rgb(95, 39, 205),
    s = util.rgb(0, 210, 211),
    t = util.rgb(29, 209, 161),
    z = util.rgb(52, 31, 151),
  }

  local text_scores = { "BOOSTING", "ULTRASPEED", "LIGHTSPEED", "WARPING" }
  _G.score_feedback = { text = "", scale = 5, opacity = 0, rotation = 0 }

  -- Canvases
  _G.background = love.graphics.newCanvas(window.w, window.h)
  _G.foreground = love.graphics.newCanvas(window.w, window.h)

  -- Background
  _G.star_size = math.floor(block_size / 10)
  _G.star_max_depth = 50
  _G.star_min_depth = 15
  local total_stars = math.floor((window.w + window.h) / 16)

  function _G.generate_stars()
    _G.stars = {}
    for i = 0, total_stars do
      table.insert(stars, {
        love.math.random(window.w),                      -- x
        love.math.random(window.h),                      -- y
        love.math.random(star_min_depth, star_max_depth) -- z
      })
    end
  end

  function _G.update_score(n)
    local scores = { 40, 100, 300, 1200 }
    state.score = state.score + scores[n]
    score_feedback.text = text_scores[n]

    -- Start screen shake
    state.shake_duration = .2

    -- Update camera speed based on score
    state.camera_speed = math.min(state.camera_speed + scores[n] / 10, state.max_camera_speed)

    -- Special effect for each 1000 points
    if state.score - state.previous_warp >= 1000 then
      score_feedback.text = text_scores[4]
      state.previous_warp = state.previous_warp + 1000
      state.warping = true
      state.shake_duration = state.max_warp_duration
      state.warp_duration = state.max_warp_duration
      -- Keep previous speed
      local prev_speed = state.camera_speed
      -- Set to minimum speed, then quickly move to "hyperspeed"
      flux.to(state, 0, { camera_speed = state.min_camera_speed })
          :after(state, state.max_warp_duration, { camera_speed = 100 })
          :after(state, .1, { camera_speed = prev_speed })
    end

    -- Update text
    flux.to(score_feedback, .1, { scale = 3, opacity = 1 })
        :after(score_feedback, .1, { scale = 4, opacity = 0 }):delay(state.max_warp_duration)
        :after(score_feedback, 0, { scale = 5 })
    if n < 4 then
      sfx.score:play()
    else
      sfx.warp:play()
    end
  end

  function _G.can_move(pos_x, pos_y, r)
    for y = 1, 4 do
      for x = 1, 4 do
        local test_x = pos_x + x
        local test_y = pos_y + y

        -- Check for solid blocks
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

  -- Creates a random tile sequence
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
    _G.inert = {}
    for y = 1, grid.y_count do
      inert[y] = {}
      for x = 1, grid.x_count do
        inert[y][x] = ' '
      end
    end

    generate_stars()
    new_sequence()
    reset_tile()
    state.score = 0
    state.timer = 0
    state.camera_speed = 10
    state.camera_y = 0
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
  end

  -- Rotate
  if k == "x" then
    local new_rotation = state.rotation + 1
    if new_rotation > #tiles[state.tile] then
      new_rotation = 1
    end

    if state.pos_y >= 0 and can_move(state.pos_x, state.pos_y, new_rotation) then
      state.rotation = new_rotation
    end
  elseif k == "z" then
    local new_rotation = state.rotation - 1
    if new_rotation < 1 then
      new_rotation = #tiles[state.tile]
    end

    if state.pos_y >= 0 and can_move(state.pos_x, state.pos_y, new_rotation) then
      state.rotation = new_rotation
    end
  end

  -- Music
  if k == "m" then
    if sfx.bg_music:getVolume() > 0 then
      sfx.bg_music:setVolume(0)
    else
      sfx.bg_music:setVolume(0.2)
    end
  elseif k == "left" then
    sfx.bg_music:setVolume(math.min(sfx.bg_music:getVolume() - .2, 1))
  elseif k == "right" then
    sfx.bg_music:setVolume(math.min(sfx.bg_music:getVolume() + .2, 1))
  end

  if k == "w" then
    update_score(4)
  end
end

function love.update(dt)
  flux.update(dt)
  if not can_move(state.pos_x, state.pos_y, state.rotation) then
    reset()
  end

  -- Update camera and timer
  state.camera_y = state.camera_y + state.camera_speed * dt
  state.timer = state.timer + state.gravity * dt

  -- Screenshake
  if state.shake_duration > 0 then
    state.shake_duration = state.shake_duration - dt
    if state.shake_wait > 0 then
      state.shake_wait = state.shake_wait - dt
    else
      state.shake_offset.x = love.math.random(-5, 5)
      state.shake_offset.y = love.math.random(-5, 5)
      state.shake_wait = 0.05
    end
  end

  -- Warping
  if state.warping then
    if state.warp_duration > 0 then
      -- Color
      -- Duration of each color
      local duration = state.max_warp_duration / #color_keys
      -- Go from min - max
      local reversed = state.max_warp_duration - state.warp_duration

      -- Calculate current and next index
      -- math.max used as first value of reversed = 0
      local index = math.max(math.ceil(reversed / duration), 1)
      local next = index + 1
      if next > #color_keys then
        next = 1
      end

      -- This took way longer than I'd like to admit
      local elapsed_time = (reversed - ((index - 1) * duration)) / duration
      -- Lerp between colors
      state.warp_color = util.lerpRGB(
        colors[color_keys[index]],
        colors[color_keys[next]],
        elapsed_time
      )
      state.warp_duration = state.warp_duration - dt
    elseif state.warp_duration < 0 then
      state.warp_duration = 0
      state.warping = false
      state.warp_color = { 1, 1, 1 }
      generate_stars()
    end
  end

  -- Drop
  if love.keyboard.isDown('s') then
    state.gravity = 20
  else
    state.gravity = 1
  end

  -- Main game logic
  if state.timer >= 0.5 then
    state.timer = 0 -- reset timer every half second
    local new_y = state.pos_y + 1
    -- check for tile movement
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
  local function draw_block(block, x, y, grid)
    grid = grid or false
    -- Ignore empty blocks if not in grid
    if block == ' ' and not grid then
      return
    end

    local border = 2
    local color = colors[block]
    local block_draw_size = block_size - border

    love.graphics.setColor(color)
    love.graphics.rectangle(
      'fill',
      (x - 1) * block_size + x_offset,
      (y - 1) * block_size + y_offset,
      block_draw_size,
      block_draw_size
    )
  end

  -- Background
  love.graphics.setCanvas(background)
  if not state.warping then
    love.graphics.clear()
  end
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

  -- Foreground
  love.graphics.setCanvas(foreground)
  love.graphics.clear()
  love.graphics.push()

  -- Screen shake
  if state.shake_duration > 0 then
    love.graphics.translate(state.shake_offset.x, state.shake_offset.y)
  end

  -- Grid
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", x_offset, y_offset, block_size * grid.x_count, block_size * grid.y_count)
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
  love.graphics.setColor(1, 1, 1)
  local volume_w = block_size / 4
  for i = 1, sfx.bg_music:getVolume() * 10 do
    love.graphics.rectangle('fill', (i - 1) * (volume_w + 2), 0, volume_w, block_size)
  end

  local x_col_offset = 2
  -- Score
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
  for y = 1, 4 do
    for x = 1, 4 do
      local block = tiles[sequence[#sequence]][1][y][x]
      if block ~= ' ' then
        draw_block(block, x + grid.x_count + x_col_offset, y + 9)
      end
    end
  end
  love.graphics.pop()
  love.graphics.setColor(1, 1, 1)

  -- Feedback text
  love.graphics.push()
  local r, g, b = unpack(state.warp_color)
  love.graphics.setColor(r, g, b, score_feedback.opacity)
  love.graphics.print(
    score_feedback.text,
    window.w / 2,
    window.h / 2,
    score_feedback.rotation,
    score_feedback.scale,
    score_feedback.scale,
    (font:getWidth(score_feedback.text) / 2),
    (font:getHeight() / 2)
  )
  love.graphics.pop()
  love.graphics.setColor(1, 1, 1)

  love.graphics.setCanvas()

  love.graphics.draw(background)
  if state.shake_duration > 0 then
    love.graphics.setShader(shaders.chromatic_aberration)
  end
  love.graphics.draw(foreground)
  love.graphics.setShader()
end
