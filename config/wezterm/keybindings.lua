local wezterm = require 'wezterm'
local act = wezterm.action

local module = {}

function module.apply_to_config(config)
  config.keys = {
    -- CMD+SHIFT+L: 左1ペイン(80%) + 右に縦2ペイン(20%, 上60%下40%)のレイアウトを作成
    {
      key = 'l',
      mods = 'CMD|SHIFT',
      action = wezterm.action_callback(function(window, pane)
        -- 右に20%のペインを作成（左80%:右20%）
        local right_pane = pane:split {
          direction = 'Right',
          size = 0.3,
        }
        -- 右ペインを縦に分割（上60%:下40%）
        right_pane:split {
          direction = 'Bottom',
          size = 0.2,
        }
      end),
    },
  }
end

return module
