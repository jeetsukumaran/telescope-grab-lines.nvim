local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("This plugins requires nvim-telescope/telescope.nvim")
end

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local make_entry = require "telescope.make_entry"
local sorters = require "telescope.sorters"

-- Based on: lua/telescope/builtin/files.lua:43 (files.live_grep)
-- Special keys:
--  opts.search_dirs -- list of directory to search in
--  opts.grep_open_files -- boolean to restrict search to open files
local grab_lines = function(opts)
  local vimgrep_arguments = opts.vimgrep_arguments or conf.vimgrep_arguments
  local search_dirs = opts.search_dirs
  local grep_open_files = opts.grep_open_files
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()

  local filelist = {}

  if grep_open_files then
    local bufnrs = filter(function(b)
      if 1 ~= vim.fn.buflisted(b) then
        return false
      end
      return true
    end, vim.api.nvim_list_bufs())
    if not next(bufnrs) then
      return
    end

    for _, bufnr in ipairs(bufnrs) do
      local file = vim.api.nvim_buf_get_name(bufnr)
      table.insert(filelist, Path:new(file):make_relative(opts.cwd))
    end
  elseif search_dirs then
    for i, path in ipairs(search_dirs) do
      search_dirs[i] = vim.fn.expand(path)
    end
  end

  local additional_args = {}
  if opts.additional_args ~= nil and type(opts.additional_args) == "function" then
    additional_args = opts.additional_args(opts)
  end

  local line_grabber = finders.new_job(function(prompt)
    -- TODO: Probably could add some options for smart case and whatever else rg offers.

    if not prompt or prompt == "" then
      return nil
    end

    local search_list = {}

    if search_dirs then
      table.insert(search_list, search_dirs)
    else
      table.insert(search_list, ".")
    end

    if grep_open_files then
      search_list = filelist
    end

    return vim.tbl_flatten { vimgrep_arguments, additional_args, "--", prompt, search_list }
  end, opts.entry_maker or make_entry.gen_from_vimgrep(
    opts
  ), opts.max_results, opts.cwd)
  -- print(line_grabber())
  pickers.new(opts, {
    prompt_title = "Grab Lines",
    -- finder = finders.new_table { results = search_list, entry_maker = opts.entry_maker },
    finder = line_grabber,
    previewer = conf.grep_previewer(opts),
    -- TODO: It would be cool to use `--json` output for this
    -- and then we could get the highlight positions directly.
    sorter = sorters.highlighter_only(opts),
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
