# A Löve file picker

Tested on Android and Linux.

![video](./video.gif)

## Usage

```lua
local picker = require 'picker'

local selected_file
picker.open('/', function(selected)
  selected_file = selected
  picker.close()
end)
```

## Options

```lua
picker.width -- default love.graphics.getWidth()
picker.height -- default love.graphics.getHeight()
picker.font_size
picker.spacing -- line spacing
picker.padding
picker.px -- default 0
picker.py -- default 0
picker.bg_color -- backgroud color
picker.border_color
picker.dir_color -- color for directories
picker.sym_color -- color for symlinks
picker.exe_color -- color for executables
picker.file_color -- color for standard files
picker.resolve -- callback that receives the selected file
picker.font
```

