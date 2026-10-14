-- Dependencies: black-metal-theme-neovim, suda.vim (bundled in pack/), shfmt, prettier, stylua (optional, format on save)

local formatters = {
  sh = { "shfmt", "-i", "2" },
  bash = { "shfmt", "-i", "2" },
  markdown = { "prettier", "--parser", "markdown", "--prose-wrap", "preserve" },
  lua = { "stylua", "--indent-type", "Spaces", "--indent-width", "2", "-" },
}

vim.opt.winbar = " "
-- vim.opt.foldcolumn = "1"
vim.opt.number = true
vim.g.mapleader = " "
-- Copy selection to system clipboard
vim.keymap.set("v", "<leader>y", '"+y')
-- Copy entire file to system clipboard
vim.keymap.set("n", "<leader>Y", "<cmd>%y+<CR>")
-- Paste from system clipboard
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p')

vim.opt.termguicolors = true

-- Changes are theme scoped
require("black-metal").setup({
  theme = "bathory",
  highlights = {
    ["@variable"] = { fg = "#c8c8c8" },
    ["@variable.member"] = { fg = "#b0b0b0" },
    ["@function"] = { fg = "#d0b080" },
  },
})
vim.cmd.colorscheme("bathory")

-- Font color for statusline
for name, fg in pairs({ StatusLine = "#FA907A", StatusLineNC = "#FA907A" }) do
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  hl.fg = fg
  vim.api.nvim_set_hl(0, name, hl)
end

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.sh", "*.bash", "*.md", "*.lua" },
  callback = function(args)
    local ext = vim.fn.fnamemodify(args.file, ":e")
    local key = (ext == "md") and "markdown" or ext
    local cmd = formatters[key]
    if not cmd or vim.fn.executable(cmd[1]) == 0 then
      return
    end
    local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") .. "\n"
    local out = vim.fn.system(cmd, text)
    if vim.v.shell_error == 0 then
      local view = vim.fn.winsaveview()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(out, "\n", { trimempty = true }))
      vim.fn.winrestview(view)
    end
  end,
})

vim.g.suda_smart_edit = 1
