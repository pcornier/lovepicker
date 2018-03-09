
local picker = require 'picker'

function love.load()
  picker.height = 300
  picker.width = 300
  picker.px, picker.py = 25, 25
  picker.open('/', function(sel)
    print(sel)
    picker.close()
  end)

  create_shader()
end


function create_shader()
  effect = love.graphics.newShader [[
      extern number time;
      extern number resx;
      float m(vec3 p) {
        p.z += 5. * time;
        return length(.2*sin(p.x-p.y)+cos(p/3.))-.8;
      }
      vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
      {
        vec3 d = .5 - vec3(pixel_coords,0) / resx, o = d;
        for(int i=0;i<64;i++) o += m(o) * d;
        color.xyz = abs(m(o+d)*vec3(.3,.15,.1)+m(o*.5)*vec3(.1,.05,0))*(8.-o.x/2.);
        return color;
      }
  ]]
end

local t = 0
function love.update(dt)
  t = t + dt
  effect:send('resx', love.graphics.getWidth())
  effect:send('time', t)
end


function love.draw()
  love.graphics.setShader(effect)
  love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  love.graphics.setShader()
end