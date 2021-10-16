# telescope-grab-lines.nvim

Grep for lines from files and put selected lines into current buffer.

## Requirements

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (required)

## Setup

You can setup the extension by doing

```lua
require('telescope').load_extension('grab_lines')
```

somewhere after your `require('telescope').setup()` call (in your ``init.vim`` or ``init.lua``).

Bind to key:

```vim
nnoremap <C-f>l <cmd>Telescope grab_lines<cr>
```

## Available functions

```lua
require'telescope'.extensions.grab_lines.grab_lines{}
```

or

```vim
:Telescope grab_lines
```

