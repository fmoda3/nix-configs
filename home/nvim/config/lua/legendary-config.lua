require('legendary').setup({
    -- Include builtins by default, set to false to disable
    include_builtin = true,
    -- Customize the prompt that appears on your vim.ui.select() handler
    select_prompt = 'Legendary'
})

require('legendary').keymaps({
    { '<leader>', ':Legendary<cr>', opts = { silent = true }, description = 'Show legendary' }
})
