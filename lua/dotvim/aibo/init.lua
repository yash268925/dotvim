-- aibo のプロンプトでは LSP / buffer / path の既定ソースは役に立たないため、
-- aibo 用のソースだけに差し替える。
---@param bufnr integer
---@return boolean
local function attach_sources(bufnr)
  if not vim.api.nvim_buf_get_name(bufnr):match('^aiboprompt://') then
    return false
  end

  local service = require('ix').get_completion_service({ recreate = true })
  -- e.g. filetype "aibo-prompt.aibo-tool-claude" -> "claude"
  -- (aibo.completion.claude / .codex / .gemini all share the same interface)
  local module_name = vim.bo[bufnr].filetype:match('aibo%-tool%-([%w_]+)')
  if module_name then
    local ok, slash_source = pcall(require('dotvim.aibo.sources.slash'), module_name)
    if ok then
      service:register_source(slash_source, { group = 1 })
    end
  end
  service:register_source(require('dotvim.aibo.sources.file')(), { group = 1 })
  return true
end

return require('dotvim._lib.feature').define({
  name = 'aibo',
  specs = {
    { src = 'https://github.com/lambdalisue/nvim-aibo' },
  },
  setup = function()
    vim.api.nvim_create_augroup('dotvim.aibo', { clear = true })

    -- 登録した関数は completion が有効なときだけ呼ばれるので、ここでは判定しない
    require('dotvim.completion').register_attacher(attach_sources)
    require('dotvim.aibo.claude')
    require('dotvim.aibo.prompt_close')
  end,
})
