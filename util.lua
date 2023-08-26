-- https://love2d.org/wiki/fadeColor
-- Adapted to transition between two colors without transparent

local function rgb(r, g, b)
  return {
    r / 255,
    g / 255,
    b / 255
  }
end

local function lerpRGB(color1, color2, dt)
  local in_r, in_g, in_b = unpack(color1)
  local out_r, out_g, out_b = unpack(color2)
  local r = out_r + ((in_r - out_r) * dt);
  local g = out_g + ((in_g - out_g) * dt);
  local b = out_b + ((in_b - out_b) * dt);
  return { r, g, b };
end


return {
  rgb = rgb,
  lerpRGB = lerpRGB,
}
