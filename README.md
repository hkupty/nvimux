# NVIMUX

Nvimux allows neovim to work as a tmux replacement.

It does so by mapping tmuxs keybindings to neovim, using its windows, buffers and terminals.

### Support nvimux
Support nvimux development by sending me some bitcoins at `1P4iGMqrBcjdgicC1EdQFA4qF91LtRri1Y`.

## Configuring

Nvimux is built on [lua](https://github.com/neovim/neovim/pull/4411), meaning that you must use a somewhat recent version of neovim.

For the older version, based on viml, refer to [the legacy branch](https://github.com/hkupty/nvimux/tree/legacy). The legacy branch won't be maintained but will be kept for those who prefer it.

To configure nvimux, you can use both lua and viml to configure, though the first is much preferred.

A lua-based configuration for nvimux is as follows:

```lua
lua << EOF
-- Nvimux configuration
local nvimux = require('nvimux')
nvimux.setup{
  config = {
    prefix = '<C-a>',
  },
  bindings = {
    {{'n', 'v', 'i', 't'}, 's', nvimux.commands.horizontal_split},
    {{'n', 'v', 'i', 't'}, 'v', nvimux.commands.vertical_split},
  }
}
EOF
```

In case you don't set configuration options, please do run the following for nvimux to work:
```lua
lua require('nvimux').setup{}
```

## Credits & Stuff

This plugin is developed and maintained by [Henry Kupty](http://github.com/hkupty) and it's completely free to use.
The rationale behind the idea is described [in this article](http://hkupty.github.io/2016/Ditching-TMUX/).
Consider helping by opening issues, Pull Requests or influencing your friends and colleagues to use!
