--- Neovim as a tmux replacement
-- nvimux is a wrapper on top of neovim's binding API
-- that conveniently sets up tmux bindings to neovim.
-- @author hkupty
-- @module nvimux
-- luacheck: globals unpack

local nvimux = {}
local bindings = require('nvimux.bindings')
local fns = require('nvimux.fns')

nvimux.config = {}
nvimux.term = {}
nvimux.commands = setmetatable({},{

__newindex = function(tbl, key, value)
    if vim.api.nvim_add_user_command then
      vim.api.nvim_add_user_command("Nvimux"..fns.snake_to_pascal(key),
        function(opts)
          value(opts.args, opts)
        end, {})
    else
      vim.api.nvim_command('command! Nvimux'..fns.snake_to_pascal(key).." lua require'nvimux'.commands."..key.."()")
    end
    rawset(tbl, key, value)
  end
})

bindings.map_table = {}

local win_cmd = function(create_window)
  vim.cmd(create_window)
  fns.fn_or_command(nvimux.context.new_window)
end

local tab_cmd = function(create_window)
  vim.cmd(create_window)
  fns.fn_or_command(nvimux.context.new_tab)
end

-- [[ Top-level helper functions
nvimux.set_last_tab = function(tabn)
  if tabn == nil then
    tabn = vim.fn.tabpagenr()
  end

  nvimux.context.state.last_tab = tabn
end

nvimux.go_to_last_tab = function()
  vim.cmd((nvimux.context.state.last_tab or 1)  .. 'tabn')
end

nvimux.go_to_tab = function(number)
  local current_tabs = vim.api.nvim_list_tabpages()

  vim.api.nvim_set_current_tabpage(current_tabs[number])
end


nvimux.do_autocmd = function(commands)
  local au = {"augroup nvimux"}
  for _, v in ipairs(commands) do
    table.insert(au, "au! " .. v.event .. " " .. v.target .. " " .. v.cmd)
  end
  table.insert(au, "augroup END")
  vim.fn.execute(au)
end
-- ]]


-- [[ Quickterm
nvimux.term.new_toggle = function()
  local split_type = nvimux.context.quickterm:split_type()
  vim.cmd(split_type)
  fns.fn_or_command(nvimux.context.quickterm.command)
  local buf_nr = vim.api.nvim_get_current_buf()
  vim.wo.wfw = true
  vim.b[buf_nr].nvimux_buf_orientation = split_type
  vim[nvimux.context.quickterm.scope].nvimux_last_buffer_id = buf_nr
end

nvimux.term.toggle = function()
  -- TODO Allow external commands
  local buf_nr = vim[nvimux.context.quickterm.scope].nvimux_last_buffer_id

  if not buf_nr then
    nvimux.term.new_toggle()
  else
    local window = vim.fn.bufwinid(buf_nr)

    if window == -1 then
      if vim.api.nvim_buf_is_loaded(buf_nr) then
        local split_type = vim.b[buf_nr].nvimux_buf_orientation
        vim.cmd(split_type)
        vim.api.nvim_win_set_buf(0, buf_nr)
      else
        nvimux.term.new_toggle()
      end
    else
      vim.api.nvim_win_hide(window)
    end
  end
end

nvimux.term.rename = function()
  vim.ui.input(
    {prompt = 'nvimux > New term name: '},
    function(name)
      nvimux.term_only{
        cmd = name,
        action = function(k) vim.api.nvim_command('file term://' .. k) end
      }
    end)
end

nvimux.term_only = function(options)
  local action = options.action or vim.api.nvim_command
  if vim.bo.buftype == 'terminal' then
    action(options.cmd)
  else
    print("Not on terminal")
  end
end

-- ]]

-- [[ Commands
-- Commands defined in `nvimux.commands` will be automatically converted to nvim's command
nvimux.commands.horizontal_split = function() return win_cmd[[spl|wincmd j]] end
nvimux.commands.vertical_split = function() return win_cmd[[vspl|wincmd l]] end
nvimux.commands.new_tab = function() return tab_cmd[[tabe]] end
nvimux.commands.previous_tab = nvimux.go_to_last_tab
nvimux.commands.term_paste = function(reg) vim.paste(vim.fn.getreg(reg or '"', 1, true), -1) end
nvimux.commands.toggle_term = nvimux.term.toggle
nvimux.commands.term_rename = nvimux.term.rename
-- ]]

local autocmds = {
  {event = "TabLeave", target="*", cmd = [[lua require('nvimux').set_last_tab()]]},
}

local mappings = {
  -- Reload global configs
  {{'n', 'v', 'i'},      '<C-r>', '<Cmd>source $MYVIMRC'},

  -- Window management
  {{'n', 'v', 'i', 't'}, '!',  '<Cmd>wincmd T<CR>'},
  {{'n', 'v', 'i', 't'}, '%',  nvimux.commands.vertical_split},
  {{'n', 'v', 'i', 't'}, '\"', nvimux.commands.horizontal_split},
  {{'n', 'v', 'i', 't'}, '-',  nvimux.go_to_last_tab},
  {{'n', 'v', 'i', 't'}, 'q',  nvimux.term.toggle },
  {{'n', 'v', 'i', 't'}, 'w',  '<Cmd>tabs<CR>'},
  {{'n', 'v', 'i', 't'}, 'o',  '<C-w>w'},
  {{'n', 'v', 'i', 't'}, 'n',  'gt'},
  {{'n', 'v', 'i', 't'}, 'p',  'gT'},
  {{'n', 'v', 'i'},      'x',  '<Cmd>bdelete %<CR>'},
  {{'t'},                'x',  function() vim.api.nvim_buf_delete(0, {force = true}) end},
  {{'n', 'v', 'i'},      'X',  '<Cmd>enew \\| bd #<CR>'},

  -- Moving around
  {{'n', 'v', 'i', 't'}, 'h',  '<C-w><C-h>'},
  {{'n', 'v', 'i', 't'}, 'j',  '<C-w><C-j>'},
  {{'n', 'v', 'i', 't'}, 'k',  '<C-w><C-k>'},
  {{'n', 'v', 'i', 't'}, 'l',  '<C-w><C-l>'},

  -- Term facilities
  {{'t'},                ':',  ':', suffix = ''},
  {{'t'},                '[',  '<C-\\><C-n>'},
  {{'t'},                ']',  nvimux.commands.term_paste },
  {{'t', 'n'},           ',',  nvimux.term.rename},

  -- Tab management
  {{'n', 'v', 'i', 't'}, 'c',  nvimux.commands.new_tab},
  {{'n', 'v', 'i', 't'}, '0',  function() nvimux.go_to_tab(10) end},
  {{'n', 'v', 'i', 't'}, '1',  function() nvimux.go_to_tab(1) end},
  {{'n', 'v', 'i', 't'}, '2',  function() nvimux.go_to_tab(2) end},
  {{'n', 'v', 'i', 't'}, '3',  function() nvimux.go_to_tab(3) end},
  {{'n', 'v', 'i', 't'}, '4',  function() nvimux.go_to_tab(4) end},
  {{'n', 'v', 'i', 't'}, '5',  function() nvimux.go_to_tab(5) end},
  {{'n', 'v', 'i', 't'}, '6',  function() nvimux.go_to_tab(6) end},
  {{'n', 'v', 'i', 't'}, '7',  function() nvimux.go_to_tab(7) end},
  {{'n', 'v', 'i', 't'}, '8',  function() nvimux.go_to_tab(8) end},
  {{'n', 'v', 'i', 't'}, '9',  function() nvimux.go_to_tab(9) end},
}

-- ]]

--- Configure nvimux to start with the supplied arguments
-- It can be configured to use the defaults by only supplying an empty table.
-- This function must be called to initalize nvimux.
-- @function nvimux.setup
-- @tparam opts table of configuration
-- @tparam opts.config table properties for nvimux
-- @tparam opts.bindings table Bindings to be configured with nvimux
-- @tparam opts.autocmds table autocmds that belong to the same logical group than nvimux
-- @see nvimux.vars for the defaults
nvimux.setup = function(opts)
  local context = vim.tbl_deep_extend("force", require('nvimux.vars'), opts.config or {})

  context.bindings = mappings
  for _, b in ipairs(opts.bindings) do
    table.insert(context.bindings, b)
  end

  for _, binding in ipairs(context.bindings) do
    bindings.keymap(binding, context)
  end

  context.autocmds = vim.tbl_deep_extend("force", autocmds, opts.autocmds or {})
  nvimux.do_autocmd(context.autocmds)

  context.state = {}

  nvimux.context = context
end

return nvimux
