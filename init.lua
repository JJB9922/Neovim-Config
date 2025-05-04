-- Basic editor settings
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.completeopt = { "menuone", "noselect" }
vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
vim.opt.pumheight = 1;
vim.opt.signcolumn = "yes";
vim.opt.wrap = false;
vim.opt.colorcolumn = "100"

-- Keymaps for LSP
vim.keymap.set("n", "<space>f", vim.lsp.buf.format, {})
vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
vim.keymap.set("n", "<leader>e", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>E", vim.diagnostic.goto_prev)

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local opts = { buffer = ev.buf }
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    end,
})

-- Format on save
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function()
        vim.lsp.buf.format({ async = true })
    end,
})

vim.keymap.set("n", "<leader>w", ":w<CR>", {})

-- Install lazy.nvim if not present
local lazypath = vim.fn.stdpath("data") .. "\\lazy\\lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim",
        "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin setup
require("lazy").setup({
    { "neovim/nvim-lspconfig" },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true
    },
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-emoji",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local cmp = require("cmp")
            
            local has_words_before = function()
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end
            
            cmp.setup({
                sources = {
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                    { name = "emoji" },
                },
                view = {
                    entries = { name = "custom", selection_order = "near_cursor" }
                },
                window = {
		    completion = cmp.config.window.bordered({
        	    winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
        	    col_offset = -3,
       		    side_padding = 0,
   		    }),
                    documentation = cmp.config.window.bordered({ hidden = true }),
                },
                experimental = {
                    ghost_text = {
                        hl_group = "CmpGhostText",
                    },
                },
                completion = {
                    keyword_length = 4, 
                    completeopt = "menu,menuone,noselect",
                },
                formatting = {
                    format = function(_, vim_item) 
                        vim_item.abbr = vim_item.abbr or ""
                        vim_item.kind = ""
                        vim_item.menu = ""
                        return vim_item
                    end,
                },
                mapping = {
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.confirm({ select = true })
                        elseif vim.snippet and vim.snippet.active({ direction = 1 }) then
                            vim.schedule(function()
                                vim.snippet.jump(1)
                            end)
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    ['<Esc>'] = cmp.mapping.abort(),
                },
            })
        end,
    },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local telescope = require("telescope")
            telescope.setup()
            vim.keymap.set("n", "<leader>sf", require("telescope.builtin").find_files, { desc = "Find files" })
            vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep, { desc = "Live grep" })
        end,
    },
    {
        "rose-pine/neovim",
        name = "rose-pine",
        config = function()
            vim.cmd("colorscheme rose-pine")
        end
    }
})

-- LSP Setup
require("lspconfig").clangd.setup({
    cmd = { "clangd", "--background-index" },
})

require("lspconfig").zls.setup({})

-- Keybinding to open adhoc term
vim.keymap.set("n", "<leader>t", function()
  vim.cmd("split | terminal")
end, {})

-- Keybinding to run build.bat in the current directory in a horizontal split
vim.keymap.set('n', '<F1>', function()
    local cwd = vim.fn.getcwd() 
    local command = 'cmd.exe /c build.bat'
    vim.cmd('split | terminal ' .. command)
end, { desc = "Run build.bat in a split" })

-- Keybinding to run the first .exe file found in the build directory in a horizontal split
vim.keymap.set('n', '<F3>', function()
    local cwd = vim.fn.getcwd()
    local build_dir = cwd .. "\\build"
    
    local exe_file = vim.fn.glob(build_dir .. "\\*.exe", true, true)
    
    if #exe_file > 0 then
        local command = 'cmd.exe /c "' .. exe_file[1] .. '"'
        vim.cmd('split | terminal ' .. command)
    else
        print("No .exe file found in the build directory.")
    end
end, { desc = "Run first .exe in build directory in a split" })

-- Keybinding to close terminal windows easily
vim.keymap.set('n', '<C-w>q', function()
    vim.cmd('q')
end, { desc = "Close terminal window" })

-- Keybinding to open new vert buffer
vim.keymap.set("n", "<leader>v", function()
    vim.cmd("vsplit | enew")
end, { desc = "Vertical split and open new buffer" })
