local wezterm = require 'wezterm'
local config = wezterm.config_builder()

require('appearance').apply_to_config(config)
require('keybindings').apply_to_config(config)
require('general').apply_to_config(config)

return config