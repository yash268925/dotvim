# dotvim

個人用の Neovim 設定を、機能ごとに opt-in で有効にできるプラグインにまとめたもの。
`vim.pack` を前提とする。require しただけでは何も起きず、`setup` を呼んだ機能だけが有効になる。

## 導入

`~/.config/nvim/init.lua`:

```lua
vim.pack.add({ 'https://github.com/yash268925/dotvim' })

require('dotvim').setup({
  base = {},
  ui = {},
  picker = {},
  lsp = {},
  completion = {},
  quickfix = {},
  skk = {},
  git = {},
  aibo = {},
  java = {},
  ['term-edit'] = {},
  ['color-picker'] = {},
  ['md-render'] = {},
  ['ja-doc'] = {},
  -- ['hl-marker'] = {},
})
```

- 値は opts の表。`true` は `{}` と同じ。書かない、または `false` の機能は有効にならない。
- 一括 setup は全機能のプラグインをまとめて 1 回の `vim.pack.add` で入れるので、初回のインストール確認も 1 回で済む。
- 機能ごとに `require('dotvim.<機能名>').setup(opts)` を呼んでもよい。

```lua
vim.pack.add({ 'https://github.com/yash268925/dotvim' })

require('dotvim.base').setup()
require('dotvim.ui').setup()
require('dotvim.lsp').setup({ servers = { 'lua_ls', 'ts_ls' } })
```

更新は `:lua vim.pack.update({ 'dotvim' })`。

### 手元の clone を使う

`vim.pack.add` の src にローカルパスを渡すと clone した複製が使われ、作業ツリーの変更が反映されない。
開発中は clone を runtimepath に直接足す。

```lua
local dev = vim.fs.normalize('~/work/dotvim')
if vim.uv.fs_stat(dev) then
  vim.opt.runtimepath:prepend(dev)
else
  vim.pack.add({ 'https://github.com/yash268925/dotvim' })
end

require('dotvim').setup({ ... })
```

## 機能

| 機能 | 内容 | opts (既定値) |
|---|---|---|
| `base` | オプション、キーマップ、autocmd、ユーザーコマンド、nohlsearch / undotree、ui2 | `shell = 'fish'`, `ui2 = true` |
| `ui` | colorscheme (nordfox)、statusline、fidget、mini.indentscope、nvim-ufo | なし |
| `picker` | nvim-deck | なし |
| `lsp` | nvim-lspconfig と `vim.lsp.enable`、LspAttach のキーマップ、nvim-treesitter (パーサのインストールとハイライト) | `servers` (有効にするサーバー名の一覧)、`treesitter = { indent = false }` (treesitter による indentexpr) |
| `completion` | nvim-cmp-kit / nvim-ix | なし |
| `quickfix` | vim-ripgrep (`:Grep`)、vim-toggle-quickfix、vim-qfedit | なし |
| `skk` | skkelua.nvim | `config` (skkelua に渡す表。既定値に deep merge し、辞書のリストは差し替え)、`skkserv = { host?, port?, encoding? }` または `true` (skkserv をローカル辞書の後に併用する。省略したフィールドと `true` は skkelua の既定値 127.0.0.1:1178 / euc-jp。`config.sources` を指定した場合はそちらを優先) |
| `git` | vim-gin (denops)、mini.diff | なし |
| `aibo` | nvim-aibo、`:Claude`、プロンプトの補完ソース | なし |
| `java` | nvim-jdtls、`:JdtlsAndroidLibs` | なし |
| `term-edit` | term-edit.nvim | `prompt_end = '❯❮ '` |
| `color-picker` | ccc.nvim | なし |
| `hl-marker` | vim-quickhl | なし |
| `md-render` | md-render.nvim | なし |
| `ja-doc` | vimdoc-ja と helplang | なし |

機能間の連携は、相手の機能が有効なときだけ働く (例: `aibo` のプロンプト補完は `completion`、コンソールの `;s` `;m` は `picker` が有効なとき)。

### java

プロジェクト固有の値は、プロジェクトルートの `.nvim.lua` で `vim.g.dotvim_jdtls` に設定する (書式は `lua/dotvim/java/jdtls.lua` の冒頭)。
`.nvim.lua` を読むには `exrc = true` が要る。`base` が有効にするので、`base` を使わない場合は別途設定する。

`:JdtlsAndroidLibs [モジュール...]` は、Android モジュールの依存 JAR の一覧を Gradle で生成し、そのモジュールの jdtls を作り直す。
引数を省くと現在のバッファが属するモジュールを対象にする。build.gradle などの編集中にも使える。
`variant` を変えたときは再実行する。
