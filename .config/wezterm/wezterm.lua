-- Import the wezterm module
local wezterm = require("wezterm")
-- Creates a config object which we will be adding our config to
local config = wezterm.config_builder()

config.color_scheme = "Tokyo Night"

-- Slightly transparent and blurred background
config.window_background_opacity = 0.9
config.macos_window_background_blur = 30

-- Smaller frame
config.window_decorations = "RESIZE"

-- Tab bar location
config.tab_bar_at_bottom = false

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
tabline.setup()

return config
