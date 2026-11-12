return require('dotvim._lib.feature').define({
  name = 'skk',
  specs = {
    { src = 'https://github.com/kjuq/skkelua.nvim', version = 'master' },
  },
  defaults = {
    config = {
      eggLikeNewline = true,
      immediatelyDictionaryRW = true,
      registerConvertResult = true,
      setUndoPoint = true,
      globalDictionaries = {
        '~/.local/share/skk/SKK-JISYO.L',
        '~/.local/share/skk/SKK-JISYO.emoji-ja.utf8',
        '~/.local/share/skk/SKK-JISYO.emoji.utf8',
      },
      userDictionary = '~/.local/share/skk/skk-jisyo.utf8',
    },
  },
  setup = function(opts)
    local config = vim.deepcopy(opts.config)
    if opts.skkserv then
      -- true は skkelua の既定の接続先をそのまま使う指定
      local server = opts.skkserv == true and {} or opts.skkserv
      config.skkServerHost = server.host
      config.skkServerPort = server.port
      config.skkServerReqEnc = server.encoding
      config.skkServerResEnc = server.encoding
      config.sources = config.sources or { 'skk_dictionary', 'skk_server' }
    end
    require('skkelua').config(config)

    local function initialize()
      vim.defer_fn(function()
        require('skkelua').initialize()
      end, 100)
    end

    -- 辞書ロードは同期で数百 ms かかり、未初期化だと初回の有効化時に待たされる。
    -- 起動中に読むと起動が遅れるので、UI の描画を終えた後に読み込んでおく。
    -- 起動後に setup された場合は UIEnter がもう来ないため、すぐに予約する。
    if vim.v.vim_did_enter == 1 then
      initialize()
    else
      vim.api.nvim_create_autocmd('UIEnter', {
        group = vim.api.nvim_create_augroup('dotvim.skk', { clear = true }),
        once = true,
        callback = initialize,
      })
    end

    require('dotvim._lib.utils').keymaps({
      { { 'i', 'c', 't' }, '<M-j>', '<Plug>(skkelua-toggle)' },
    })
  end,
})
