-- Dependencies: black-metal-theme-neovim, suda.vim (bundled in pack/), shfmt, prettier, stylua, c_formatter_42, csharpier, ruff, gofmt, taplo (optional, format on save)

-- Formatters by file extension. Each takes the file path and returns a command
-- that reads the buffer on stdin and writes the result to stdout.
local function prettier(file)
  -- The path only selects the parser and the project's .prettierrc.
  return { "prettier", "--stdin-filepath", file }
end

-- 42 school norm; pipx install c-formatter-42
local function norm_42()
  return { "c_formatter_42" }
end

local formatters = {
  go = function()
    return { "gofmt" }
  end,
  py = function(file)
    return { "ruff", "format", "--stdin-filename", file, "-" }
  end,
  toml = function()
    return { "taplo", "format", "-" }
  end,
  sh = function()
    return { "shfmt", "-i", "2" }
  end,
  lua = function()
    return { "stylua", "--indent-type", "Spaces", "--indent-width", "2", "-" }
  end,
  c = norm_42,
  h = norm_42,
  cs = function(file)
    return { "csharpier", "format", "--write-stdout", "--stdin-path", vim.fn.fnamemodify(file, ":p") }
  end,
  json = prettier,
  yaml = prettier,
  js = prettier,
  ts = prettier,
  css = prettier,
  md = prettier,
}
formatters.bash = formatters.sh
formatters.yml = formatters.yaml

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

local patterns = vim.tbl_map(function(ext)
  return "*." .. ext
end, vim.tbl_keys(formatters))

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = patterns,
  callback = function(args)
    local build = formatters[vim.fn.fnamemodify(args.file, ":e")]
    local cmd = build and build(args.file)
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
