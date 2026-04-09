local wezterm = require 'wezterm'

local module = {}

function module.apply_to_config(config)
  -- フォント設定
  config.font_size = 10

  -- カラースキーム
  config.color_scheme = 'Tokyo Night'

  -- ウィンドウの透過設定
  config.window_background_opacity = 0.9
  config.text_background_opacity = 0.1

end
return module
