
--require 'lib.lovedebug'

local picker = {mt = {}}
setmetatable(picker, picker.mt)

local W = love.graphics.getWidth()
local H = love.graphics.getHeight()

-- default values
picker._p = {
  width = W,
  height = H,
  font_size = H * 0.03,
  spacing = (H * 0.03) * 0.1,
  padding = 10,
  px = 0,
  py = 0,
  bg_color = {55, 55, 60},
  border_color = {100, 100, 100},
  dir_color = {255, 255, 0},
  sym_color = {255, 0, 255},
  exe_color = {255, 0, 0},
  file_color = {255, 255, 255},
  resolve = function(s) print(s) end,
  font = love.graphics.newFont(H * 0.03)
}

picker.mt.__index = function(t,k)
  if t._p[k] ~= nil then
    return t._p[k]
  else
    return t.__ClassDict[k]
  end
end

picker.mt.__newindex = function(t,k,v)
  if t._p[k] ~= nil then
    if k == 'height' then
      local fs = math.max(20, v * 0.03)
      t._p['font_size'] = fs
      t._p['spacing'] = fs * 0.1
      t._p['font'] = love.graphics.newFont(fs)
    elseif k == 'font_size' then
      t._p['font'] = love.graphics.newFont(v)
    end
    t._p[k] = v
  else
    rawset(t, k, v)
  end
end

local drag = false
local scroll = 0
local files = {}
local box_height = 0
local selection = ''
local path = '/'
local handlers = {}

-- call if it exists
local function _call(fn)
  if fn then fn() end
end

-- print text
local function text(text, x, y)
  local t = string.sub(text, -1)
  if t == '/' then
    love.graphics.setColor(picker.dir_color)
  elseif t == '*' then
    love.graphics.setColor(picker.exe_color)
    text = string.sub(text, 1, -2)
  elseif t == '@' then
    love.graphics.setColor(picker.sym_color)
    text = string.sub(text, 1, -2)
  else
    love.graphics.setColor(picker.file_color)
  end
  love.graphics.print(text, x, y)
end

function picker.mousepressed(x, y, btn, touch)
  _call(handlers.mousepressed)
  if x >= picker.px and x <= picker.width + picker.px and y >= picker.py and y <= picker.height + picker.py then
    drag = y
  else
    drag = false
  end
end

function picker.mousereleased(x, y, btn, touch)
  _call(handlers.mousereleased)
  if drag and math.abs(drag - y) < 10 and (x >= picker.px and x <= picker.width + picker.px) and (y >= picker.py and y <= picker.height + picker.py) then
    local i = math.ceil((y - scroll - picker.py + picker.padding) / (picker.font_size + picker.spacing)) -1
    if selection == files[i] then
      -- is a directory
      if string.sub(selection, -1) == '/' and selection ~= './' then
        if selection == '../' then
          path = path:gsub('/[^/]+/$', '/')
        else
          path = path .. selection
        end
        files = picker.get_files()
        if #files == 0 then
          files[1] = '../'
        end
        box_height = (picker.font_size + picker.spacing) * #files
        scroll = 0
      -- or a file
      else
        selection = selection:gsub('[%*@]$', '')
        picker.resolve(path .. selection)
      end
    elseif files[i] then
      selection = files[i]
    end
  end
  drag = false
end



function picker.mousemoved(x, y, dx, dy, touch)
  _call(handlers.mousemoved)
  if drag then
    scroll = scroll + dy
    scroll = math.max(picker.height - box_height - picker.font_size - picker.padding, scroll)
    scroll = math.min(0, scroll)
  end
end

function picker.wheelmoved(x, y)
  scroll = scroll + y * 100
  scroll = math.max(picker.height - box_height - picker.font_size - picker.padding, scroll)
  scroll = math.min(0, scroll)
end

-- to do: platform detection
function picker.get_files()
  local files, i = {}, 1
  local pfile = io.popen('ls -Fa ' .. path)
  for filename in pfile:lines() do
    if filename ~= './' then
      files[i] = filename
      i = i + 1
    end
  end
  return files
end

function picker.draw()
  _call(handlers.draw)
  local default = love.graphics.getFont()

  -- mask
  love.graphics.stencil(function()
    love.graphics.rectangle('fill', picker.px + picker.padding, picker.py + picker.padding, picker.width - picker.padding * 2, picker.height - picker.padding * 2)
  end, 'replace', 1)

  -- window
  love.graphics.setColor(picker.bg_color)
  love.graphics.rectangle('fill', picker.px, picker.py, picker.width, picker.height)
  love.graphics.setColor(picker.border_color)
  love.graphics.rectangle('line', picker.px, picker.py, picker.width, picker.height)

  -- file names
  love.graphics.setStencilTest('greater', 0)
  love.graphics.setFont(picker.font)
  for i, filename in ipairs(files) do
    local y = i * (picker.font_size + picker.spacing) + scroll - picker.padding
    if y + picker.font_size + picker.spacing >= 0 and y < picker.height then
      if selection == filename then
        love.graphics.setColor({128,128,128})
        love.graphics.rectangle("fill", picker.px + picker.padding, picker.py + y + picker.spacing, picker.width, picker.font_size)
      end
      text(filename, picker.px + picker.padding, picker.py + y)
    end
  end
  love.graphics.setFont(default)
  love.graphics.setStencilTest()
end

function picker.open(here, res)
  path = here
  picker.resolve = res
  files = picker.get_files()
  box_height = (picker.font_size + picker.spacing) * #files

  -- save love callbacks & replace
  local fnames = {
    'mousemoved',
    'mousereleased',
    'mousepressed',
    'wheelmoved',
    'draw'
  }

  for i, fn in ipairs(fnames) do
    handlers[fn] = love[fn] or false
    love[fn] = picker[fn]
  end
end

function picker.close()
  -- restore callbacks
  for k, fn in pairs(handlers) do
    love[k] = fn or nil
  end
end

return picker
