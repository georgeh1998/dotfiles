local wezterm = require 'wezterm'
local act = wezterm.action

local module = {}

function module.apply_to_config(config)
  config.keys = {
    -- CMD+SHIFT+L: 左上/左下(9:1) + 右上/右下のレイアウトを作成
    {
      key = 'l',
      mods = 'CMD|SHIFT',
      action = wezterm.action_callback(function(window, pane)
        -- 右に40%のペインを作成（左60%:右40%）
        local right_pane = pane:split {
          direction = 'Right',
          size = 0.4,
        }
        -- 右ペインを縦に分割（上80%:下20%）
        right_pane:split {
          direction = 'Bottom',
          size = 0.2,
        }
        -- 左ペインを縦に9:1で分割（左上90%:左下10%）
        pane:split {
          direction = 'Bottom',
          size = 0.1,
        }
      end),
    },
  }
end

return module
