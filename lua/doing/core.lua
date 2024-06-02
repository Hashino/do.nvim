local C = {}
local view = require("doing.view")
local edit = require("doing.edit")
local store = require("doing.store")
local state = require("doing.state").state
local default_opts = require("doing.state").default_opts
local utils = require("doing.utils")

---Show a message for the duration of `options.message_timeout`
---@param str string Text to display
---@param hl? string Highlight group
function C.show_message(str, hl)
  state.message = string.rep(' ', vim.fn.winwidth(0) - 4 - string.len(str)) .. str

  vim.defer_fn(function()
    state.message = nil
    C.redraw_winbar()
  end, default_opts.message_timeout)

  C.redraw_winbar()
end

---add a task to the list
---@param str string task to add
---@param to_front boolean whether to add task to front of list
function C.add(str, to_front)
  state.tasks:add(str, to_front)
  C.redraw_winbar()
  utils.exec_task_modified_autocmd()
end

--- Finish the first task
function C.done()
  if not state.tasks:has_items() then
    C.show_message(" There was nothing left to do ", "InfoMsg")
    return
  end

  state.tasks:shift()

  if state.tasks:count() == 0 then
    C.show_message(" All tasks done ", "TablineSel")
  else
    C.show_message(state.tasks:count() .. " left.", "MoreMsg")
  end

  utils.exec_task_modified_autocmd()
end

--- Edit the tasks in a floating window
function C.edit()
  edit.toggle_edit(state.tasks:get(), function(new_todos)
    state.tasks:set(new_todos)
    utils.exec_task_modified_autocmd()
  end)
  C.redraw_winbar()
end

--- save the tasks
function C.save()
  state.tasks:sync(true)
end

---Setup doing.nvim
---@param opts DoOptions
function C.setup(opts)
  state.options = vim.tbl_deep_extend("force", default_opts, opts or {})
  state.tasks = store.init(state.options.store)
  local winbar_options = state.options.winbar

  C.setup_winbar(winbar_options)

  return C
end

---configure displaying current to do item in winbar
---@param options WinbarOptions|boolean
function C.setup_winbar(options)
  options = utils.parse_winbar_options(options)

  if not options then
    return
  end

  vim.g.winbar = view.stl_nc
  vim.api.nvim_win_set_option(0, "winbar", view.stl)

  state.auGroupID = vim.api.nvim_create_augroup("doing_nvim", { clear = true })

  -- winbar should not be displayed in windows the cursor is not in
  vim.api.nvim_create_autocmd({ "WinEnter", "WinLeave", "BufEnter", "BufLeave" }, {
    group = state.auGroupID,
    callback = function()
      C.redraw_winbar()
    end,
  })
end

function C.disable_winbar()
  if not state.auGroupID then
    return -- already disabled
  end

  for _, value in ipairs(vim.api.nvim_list_wins()) do
    if vim.fn.win_gettype() == "" then
      vim.api.nvim_win_set_option(value, "winbar", nil)
    end
  end

  vim.api.nvim_del_augroup_by_id(state.auGroupID)
  C.hide()
end

function C.enable_winbar()
  C.setup_winbar(state.options.winbar)
end

--- toggle the visibility of the winbar
function C.toggle_winbar()
  -- disable winbar completely when not visible
  vim.wo.winbar = vim.wo.winbar == "" and view.stl or ""
  state.view_enabled = not state.view_enabled
end

function C.view(variant)
  state.tasks = store.init(state.options.store)

  if variant == "active" then
    return view.render(state)
  end

  if variant == "inactive" then
    return view.render_inactive(state)
  end
end

---for things like lualine
function C.view_inactive()
  state.tasks = store.init(state.options.store)

  return view.render_inactive(state)
end

function C.is_visible()
  return state.view_enabled and state.tasks:has_items()
end

function C.has_message()
  return not not state.message
end

function C.hide()
  vim.wo.winbar = ""

  vim.cmd([[
    set winbar=
    redrawstatus
  ]])
end

--- Redraw winbar depending on if there are tasks. Redraw if there are pending tasks, other wise set to ""
function C.redraw_winbar()
  if not utils.parse_winbar_options(state.options.winbar) then
    return
  end

  if utils.can_have_winbar() then
    if state.tasks:has_items() or C.has_message() then
      vim.wo.winbar = view.stl
    else
      C.hide()
    end
  end
end

return C
