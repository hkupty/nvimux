local bindings = {}
local vars = require('nvimux.vars')
local fns = {}

if vim.keymap ~= nil then
  bindings.set_keymap = vim.keymap.set
else
  bindings.mapping = {}
  bindings.set_keymap = function(mode, rhs, lhs, options)
    if type(lhs) == "function" then
      local id = #bindings.mapping + 1
      bindings.mapping[id] = lhs
      lhs = [[<Cmd>lua require("nvimux.bindings").do_mapping(]] .. id .. [[)<CR>]]
    end
    if type(mode) == "table" then
      for _, m in ipairs(mode) do
        vim.api.nvim_set_keymap(m, rhs, lhs, options)
      end
    else
      vim.api.nvim_set_keymap(mode, rhs, lhs, options)
    end
  end
end

bindings.do_mapping = function(ix)
  bindings.mapping[ix]()
end

bindings.keymap = function(binding, context)
  local options = {silent = true}

  if (type(binding[3]) == "function") then
    bindings.set_keymap(binding[1], context.prefix .. binding[2], binding[3], options)
  elseif (type(binding[3]) == "string") then
    local suffix = ''

    if binding.suffix == nil then
      -- TODO revisit
      suffix = string.sub(binding[3], 1, 1) == ':' and '<CR>' or ''
    else
      suffix = binding.suffix
    end

    if string.lower(string.sub(binding[3], 1, 5)) ~= "<cmd>" then
      if vim.tbl_contains(binding[1], 't') then
        binding[1] = vim.tbl_filter(function(mode) return mode ~= 't' end, binding[1])
        bindings.set_keymap('t',
          context.prefix .. binding[2],
          '<C-\\><C-n>' .. binding[3] .. suffix,
          options)
      elseif vim.tbl_contains(binding[1], 'i') then
        binding[1] = vim.tbl_filter(function(mode) return mode ~= 'i' end, binding[1])
        bindings.set_keymap('i',
          context.prefix .. binding[2],
          '<ESC>' .. binding[3] .. suffix,
          options)
      end
    end

    bindings.set_keymap(binding[1], context.prefix .. binding[2], binding[3] .. suffix, options)
  end
end

return bindings
