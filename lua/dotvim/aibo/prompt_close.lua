-- aibo は prompt の float から離れると WinLeave で即座に閉じる。skkelua の辞書登録
-- UI は enter=true の float で開くため、prompt 上で登録が始まると prompt が閉じ、
-- 登録後に変換結果を戻す先の window がなくなる。aibo に無効化の設定がないため
-- autocmd を差し替え、移り先が登録 UI のときは閉じずに残す。

-- aibo はこの autocmd をモジュールのトップレベルで 1 回だけ登録する。
-- 先に読み込んでおかないと、後から読み込まれたときに登録されて差し替えが効かない。
if not pcall(require, 'aibo.internal.prompt_window') then
  return
end
local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
  group = 'aibo_prompt_internal',
  event = 'WinLeave',
})
if not ok or #autocmds == 0 then
  return
end
for _, autocmd in ipairs(autocmds) do
  vim.api.nvim_del_autocmd(autocmd.id)
end

local enabled = require('dotvim._lib.feature').enabled

---@param winid integer
---@return boolean
local function is_float(winid)
  return vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_config(winid).relative ~= ''
end

-- 登録 UI のバッファには名前も filetype もない。buftype=prompt の無名 float で見分ける。
---@param winid integer
---@return boolean
local function is_skk_register_prompt(winid)
  if not is_float(winid) then
    return false
  end
  local bufnr = vim.api.nvim_win_get_buf(winid)
  return vim.bo[bufnr].buftype == 'prompt' and vim.api.nvim_buf_get_name(bufnr) == ''
end

---@param winid integer
local function close(winid)
  if is_float(winid) then
    pcall(vim.api.nvim_win_close, winid, false)
  end
end

-- 登録 UI へ移ったために閉じずに残した prompt の window
---@type table<integer, true>
local kept = {}

-- 移り先は WinLeave の時点では分からないので、フォーカス移動が済んでから判定する
local function settle()
  local current = vim.api.nvim_get_current_win()
  if is_skk_register_prompt(current) then
    return
  end
  for winid in pairs(kept) do
    kept[winid] = nil
    if winid ~= current then
      close(winid)
    end
  end
end

local group = vim.api.nvim_create_augroup('dotvim.aibo', { clear = false })

vim.api.nvim_create_autocmd('WinLeave', {
  group = group,
  pattern = 'aiboprompt://*',
  nested = true,
  callback = function()
    local winid = vim.api.nvim_get_current_win()
    if not is_float(winid) then
      return
    end
    if not enabled('skk') then
      pcall(vim.api.nvim_win_close, winid, false)
      return
    end
    kept[winid] = true
    vim.schedule(settle)
  end,
})

-- 登録 UI を閉じた後、prompt に戻らず別の window へ移った場合にも閉じる
vim.api.nvim_create_autocmd('WinEnter', {
  group = group,
  callback = function()
    if next(kept) then
      vim.schedule(settle)
    end
  end,
})
