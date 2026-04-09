local wezterm = require 'wezterm'

local module = {}

function module.apply_to_config(config)
  -- ウィンドウの初期サイズ（カラム数 x 行数）
  config.initial_cols = 120
  config.initial_rows = 28

  -- 設定ファイルを変更したら自動でリロードする
  config.automatically_reload_config = true

  -- タブのタイトルをカレントディレクトリ名に設定する
  -- 例: ~/Documents/dotfiles → 「dotfiles」と表示される
  wezterm.on('format-tab-title', function(tab)
    local cwd_uri = tab.active_pane.current_working_dir
    if cwd_uri then
      local path = cwd_uri.file_path
      if path then
        local dir_name = path:match('([^/]+)/?$')
        if dir_name then
          return dir_name
        end
      end
    end
  end)
end

return module
