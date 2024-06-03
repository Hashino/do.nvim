local View = {}

--- Weather the winbar should visible, when view_enabled is true, and there are items in the list
---@param state DoState
---@return boolean
function View.is_visible(state)
  return state.view_enabled and state.tasks:has_items() or not not state.message
end

---Create a winbar string for the current task
---@param state DoState
---@return string|table
function View.render(state)
  if not View.is_visible(state) then
    return { left = '', middle = '', right = '' }
  end
  local right = ""

  -- using pcall so that it won't spam error messages
  local ok, left = pcall(function()
    local count = state.tasks:count()
    local res = ""
    local aligned = false
    local current = state.tasks:current()

    if state.message then
      return state.message
    end

    if count == 0 then
      return ""
    end

    res = state.options.doing_prefix .. current

    -- append task count number if there is more than 1 task
    if count > 1 then
      right = '+' .. (count - 1) .. " more"
      aligned = true
    end

    if not state.tasks.file then
      res = res .. (aligned and "" or "%=") .. "(:DoSave)"
    end

    return res
  end)

  if not ok then
    return "ERR: " .. left
  end

  width = tonumber(vim.api.nvim_command_output("echo &columns")) or 0

  local res = {
    left = ' ' .. left,
    middle = string.rep(' ', tonumber(width) - string.len(left) - string.len(right) - 2),
    right = right .. ' ',
  }

  return res
end

function View.render_inactive(state)
  if not View.is_visible(state) then
    return ""
  end

  return "  "
end

View.stl = "%!v:lua.DoStatusline('active')"
View.stl_nc = "%!v:lua.DoStatusline('inactive')"

return View
