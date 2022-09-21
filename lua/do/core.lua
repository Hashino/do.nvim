local kaomoji = require("do.kaomojis")
local view = require('do.view')
local edit = require('do.edit')
local store = require('do.store')
local state = require('do.state').state
local default_opts = require('do.state').default_opts
local C = {}


---Show a message for the duration of `options.message_timeout`
---@param str string Text to display
---@param hl? string Highlight group
function C.show_message(str, hl)
  state.message = "%#" .. (hl or "TablineSel") .. "#" .. str

  vim.defer_fn(function()
    state.message = nil
  end, default_opts.message_timeout)
end

---@param str string
---@param to_front boolean
function C.add(str, to_front)
  state.tasks:add(str, to_front)
end

function C.done()
  if state.tasks:count() == 0 then
    C.show_message(kaomoji.confused() .. " There was nothing left to do…", "InfoMsg")
    return
  end

  state.tasks:shift()

  if state.tasks:count() == 0 then
    C.show_message(kaomoji.joy() .. " ALL DONE! " .. kaomoji.joy(), "TablineSel")
  else
    C.show_message(kaomoji.joy() .. " Great! Only " .. state.tasks:count() .. " to go.", "MoreMsg")
  end
end

function C.edit()
  edit.toggle_edit(state.tasks:get(), function(new_todos)
    state.tasks:set(new_todos)
  end)
end

function C.save()
  state.tasks:sync(true)
end

---@param opts DoOptions
function C.setup(opts)
  state.options = vim.tbl_deep_extend("force", default_opts, opts or {})
  state.tasks = store.init(state.options.store)

  return C
end

function C.toggle()
  state.view_enabled = not state.view_enabled
end

C.statusline = "%!v:lua.DoStatusline()"

function C.view()
  return view.render(state)
end

function C.view_inactive()
  return view.render_inactive(state)
end

function C.has_items()
  return state.tasks:count() > 0
end

function C.is_visible()
  return state.view_enabled and C.has_items()
end

return C
