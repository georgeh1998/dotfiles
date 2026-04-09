local wezterm = require 'wezterm'

local module = {}

function module.apply_to_config(config)
  config.initial_cols = 120
  config.initial_rows = 28
  config.automatically_reload_config = true
end

return module
