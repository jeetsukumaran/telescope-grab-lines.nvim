--
--  Based on:
--      -   lua/telescope/builtin/files.lua:43 (files.live_grep)
--      -   https://github.com/nvim-telescope/telescope-live-grep-raw.nvim
--          -   SPDX-FileCopyrightText: 2021 Michael Weimann <mail@michael-weimann.eu>
--          -   SPDX-License-Identifier: MIT

local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("This plugin requires nvim-telescope/telescope.nvim")
end


local telescope = require("telescope")
local pickers = require "telescope.pickers"
local sorters = require('telescope.sorters')
local conf = require('telescope.config').values
local make_entry = require('telescope.make_entry')
local finders = require "telescope.finders"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local tbl_clone = function(original)
  local copy = {}
  for key, value in pairs(original) do
    copy[key] = value
  end
  return copy
end

local grep_highlighter_only = function(opts)
  return sorters.Sorter:new {
    scoring_function = function() return 0 end,

    highlighter = function(_, prompt, display)
      return {}
    end,
  }
end

local grab_lines = function(opts)
  opts = opts or {}
  opts.vimgrep_arguments = opts.vimgrep_arguments or conf.vimgrep_arguments
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_vimgrep(opts)
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd)

  local cmd_generator = function(prompt)
    if not prompt or prompt == "" then
      return nil
    end

    local args = tbl_clone(opts.vimgrep_arguments)
    local prompt_parts = vim.split(prompt, " ")

    local cmd = vim.tbl_flatten { args, prompt_parts }
    return cmd
  end

  pickers.new(opts, {
    prompt_title = 'Live Grep Raw',
    finder = finders.new_job(cmd_generator, opts.entry_maker, opts.max_results, opts.cwd),
    previewer = conf.grep_previewer(opts),
    sorter = grep_highlighter_only(opts),
    attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            -- Strip leading whitespace
            -- local svalue = selection.value:gsub("^%s*(.-)%s*$", "%1")
            -- for k,v in pairs(selection) do print(k,v) end
            local svalue = selection.text
            vim.api.nvim_put({ svalue }, "l", true, true)
        end)
        return true
    end
  }):find()
end

-- to execute the function
-- grab_lines()
return telescope.register_extension({ exports = { grab_lines = grab_lines } })
